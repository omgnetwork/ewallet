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

defmodule EWallet.TransactionGate.BlockchainLocal do
  @moduledoc """
  Handles the logic for a transaction of value from an account to a user. Delegates the
  actual transaction to EWallet.LocalTransactionGate once the wallets have been loaded.
  """
  alias EWallet.TransactionFormatter
  alias EWalletDB.{BlockchainTransactionState, Transaction, TransactionState, TransactionType}
  alias EWalletDB.Helpers.Preloader
  alias ActivityLogger.System
  alias LocalLedger.Transaction, as: LedgerTransaction

  @pending TransactionState.pending()
  @blockchain_submitted TransactionState.blockchain_submitted()
  @ledger_pending_blockchain_confirmed TransactionState.ledger_pending_blockchain_confirmed()
  @blockchain_transaction_confirmed BlockchainTransactionState.confirmed()
  @blockchain_transaction_failed BlockchainTransactionState.failed()

  def process_with_transaction(transaction) do
    transaction
    |> TransactionType.get()
    |> process_with_transaction(transaction)
  end

  # The destination is nil when the transaction is intended to arrive and stay
  # in the hot wallet, not part of any local ledger wallet, not even the master wallet.
  defp process_with_transaction(:from_blockchain_to_ewallet, transaction) do
    TransactionState.transition_to(
      :from_blockchain_to_ewallet,
      TransactionState.confirmed(),
      transaction,
      %{originator: %System{}}
    )
  end

  defp process_with_transaction(:from_blockchain_to_ledger, transaction) do
    from_blockchain? = from_blockchain?(transaction)

    transaction
    |> Preloader.preload([:from_token, :to_token, :from_wallet, :to_wallet])
    |> set_blockchain_wallets(:from_wallet, :from, from_blockchain?)
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: from_blockchain?})
    |> update_transaction(transaction, :from_blockchain_to_ledger)
  end

  defp process_with_transaction(
         :from_ledger_to_blockchain,
         %Transaction{status: @pending} = transaction
       ) do
    to_blockchain? = to_blockchain?(transaction)

    transaction
    |> Preloader.preload([:from_token, :to_token, :from_wallet, :to_wallet])
    |> set_blockchain_wallets(:to_wallet, :to, to_blockchain?)
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: false, status: @pending})
    |> update_transaction(transaction, :from_ledger_to_blockchain)
  end

  defp process_with_transaction(
         :from_ledger_to_blockchain,
         %Transaction{
           local_ledger_uuid: local_ledger_uuid,
           status: @blockchain_submitted,
           blockchain_transaction: %{status: @blockchain_transaction_confirmed}
         } = transaction
       )
       when not is_nil(local_ledger_uuid) do
    {:ok, transaction} =
      TransactionState.transition_to(
        :from_ledger_to_blockchain,
        @ledger_pending_blockchain_confirmed,
        transaction,
        %{
          originator: %System{}
        }
      )

    local_ledger_uuid
    |> LedgerTransaction.confirm()
    |> update_transaction(transaction, :from_ledger_to_blockchain)
  end

  defp process_with_transaction(
         :from_ledger_to_blockchain,
         %Transaction{
           local_ledger_uuid: local_ledger_uuid,
           blockchain_transaction: %{status: @blockchain_transaction_failed}
         } = transaction
       )
       when not is_nil(local_ledger_uuid) do
    local_ledger_uuid
    |> LedgerTransaction.fail()
    |> update_transaction(transaction, :from_ledger_to_blockchain)
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

  defp to_blockchain?(transaction) do
    is_nil(transaction.to) &&
      !is_nil(transaction.to_blockchain_address) &&
      !is_nil(transaction.blockchain_identifier)
  end

  #
  # Skip errored transactions and transactions already recorded in the local ledger.
  #

  defp update_transaction(
         _,
         %Transaction{local_ledger_uuid: local_ledger_uuid, error_code: error_code} = transaction,
         _
       )
       when local_ledger_uuid != nil
       when error_code != nil do
    {:ok, transaction}
  end

  #
  # Handle transactions from blockchain to ledger
  #

  defp update_transaction(
         {:ok, ledger_transaction},
         transaction,
         :from_blockchain_to_ledger
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

  #
  # Handle transactions from ledger to blockchainn
  #

  defp update_transaction(
         {:ok, ledger_transaction},
         %{status: @pending} = transaction,
         :from_ledger_to_blockchain
       ) do
    {:ok, transaction} =
      TransactionState.transition_to(
        :from_ledger_to_blockchain,
        TransactionState.ledger_pending(),
        transaction,
        %{
          local_ledger_uuid: ledger_transaction.uuid,
          originator: %System{}
        }
      )

    {:ok, transaction}
  end

  defp update_transaction(
         {:ok, _ledger_transaction},
         %{status: @ledger_pending_blockchain_confirmed} = transaction,
         :from_ledger_to_blockchain
       ) do
    {:ok, transaction} =
      TransactionState.transition_to(
        :from_ledger_to_blockchain,
        TransactionState.confirmed(),
        transaction,
        %{
          originator: %System{}
        }
      )

    {:ok, transaction}
  end

  #
  # Handle errors recording to the local ledger
  #

  defp update_transaction({:error, code, description}, transaction, flow) do
    {description, data} =
      if(is_map(description), do: {nil, description}, else: {description, nil})

    {:ok, transaction} =
      TransactionState.transition_to(
        flow,
        TransactionState.failed(),
        transaction,
        %{
          error_code: Atom.to_string(code),
          error_description: description,
          error_data: data,
          originator: %System{}
        }
      )

    {:error, transaction}
  end
end
