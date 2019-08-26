# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.BlockchainLocalTransactionGate do
  @moduledoc """
  Handles the logic for a transaction of value from an account to a user. Delegates the
  actual transaction to EWallet.LocalTransactionGate once the wallets have been loaded.
  """
  alias EWallet.TransactionFormatter
  alias EWalletDB.{Transaction, TransactionState}
  alias EWalletDB.Helpers.Preloader
  alias ActivityLogger.System
  alias LocalLedger.Transaction, as: LedgerTransaction

  def process_with_transaction(%Transaction{status: "blockchain_confirmed"} = transaction) do
    from_blockchain? = from_blockchain?(transaction)

    transaction
    |> Preloader.preload([:from_token, :to_token, :from_wallet, :to_wallet])
    |> set_blockchain_wallets(:from_wallet, :from, from_blockchain?)
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: from_blockchain?})
    |> update_transaction(transaction)
  end

  defp set_blockchain_wallets(transaction, _, _, false), do: transaction

  defp set_blockchain_wallets(transaction, assoc, field, true) do
    case Map.get(transaction, field) do
      nil ->
        Map.put(transaction, assoc, %{address: transaction.from_blockchain_address, metadata: %{}})

      _ ->
        transaction
    end
  end

  defp from_blockchain?(transaction) do
    is_nil(transaction.from) &&
      !is_nil(transaction.from_blockchain_address) &&
      !is_nil(transaction.blockchain_identifier)
  end

  defp update_transaction(
         _,
         %Transaction{local_ledger_uuid: local_ledger_uuid, error_code: error_code} = transaction
       )
       when local_ledger_uuid != nil
       when error_code != nil do
    {:ok, transaction}
  end

  defp update_transaction(
         {:ok, ledger_transaction},
         transaction
       ) do
    {:ok, transaction} =
      TransactionState.transition_to(
        :from_blockchain_to_ledger,
        TransactionState.confirmed(),
        transaction,
        %{
          local_ledger_uuid: ledger_transaction.uuid,
          originator: %System{}
        }
      )

    {:ok, transaction}
  end

  defp update_transaction({:error, code, description}, transaction) do
    {:ok, transaction} =
      TransactionState.transition_to(
        :from_ledger_to_ledger,
        TransactionState.failed(),
        transaction,
        %{
          error_code: code,
          error_description: description,
          error_data: nil,
          originator: %System{}
        }
      )

    {:error, transaction}
  end
end
