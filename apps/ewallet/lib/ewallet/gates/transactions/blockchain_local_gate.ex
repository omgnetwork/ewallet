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
  @confirmed TransactionState.confirmed()
  @failed TransactionState.failed()
  @blockchain_submitted TransactionState.blockchain_submitted()
  @ledger_pending_blockchain_confirmed TransactionState.ledger_pending_blockchain_confirmed()
  @blockchain_transaction_confirmed BlockchainTransactionState.confirmed()
  @blockchain_transaction_failed BlockchainTransactionState.failed()

  @default_error_code "blockchain_transaction_error"
  @default_error_description "An error occured when processing this blockchain transaction"

  # This is called by the transaction tracker when a blockchain transaction
  # reaches the `confirmed` state or by the EWallet.TransactionGate.Blockchain module.
  def process_with_transaction(transaction) do
    transaction
    |> TransactionType.get()
    |> process_with_transaction(transaction)
  end

  # If the transaction is in a final state we don't need to proccess it
  defp process_with_transaction(_, %{status: @confirmed} = transaction), do: {:ok, transaction}
  defp process_with_transaction(_, %{status: @failed} = transaction), do: {:error, transaction}

  defp process_with_transaction(
         :from_blockchain_to_ewallet,
         %{blockchain_transaction: %{status: @blockchain_transaction_confirmed}} = transaction
       ) do
    TransactionState.transition_to(
      :from_blockchain_to_ewallet,
      TransactionState.confirmed(),
      transaction,
      %{originator: %System{}}
    )
  end

  defp process_with_transaction(
         :from_blockchain_to_ewallet,
         transaction
       ) do
    TransactionState.transition_to(
      :from_blockchain_to_ewallet,
      TransactionState.failed(),
      transaction,
      %{
        originator: %System{},
        error_code: @default_error_code,
        error_description: @default_error_description
      }
    )
  end

  defp process_with_transaction(
         :from_ewallet_to_blockchain,
         %{blockchain_transaction: %{status: @blockchain_transaction_confirmed}} = transaction
       ) do
    TransactionState.transition_to(
      :from_ewallet_to_blockchain,
      TransactionState.confirmed(),
      transaction,
      %{originator: %System{}}
    )
  end

  defp process_with_transaction(
         :from_ewallet_to_blockchain,
         transaction
       ) do
    TransactionState.transition_to(
      :from_ewallet_to_blockchain,
      TransactionState.failed(),
      transaction,
      %{
        originator: %System{},
        error_code: @default_error_code,
        error_description: @default_error_description
      }
    )
  end

  defp process_with_transaction(
         :from_blockchain_to_ledger,
         %{blockchain_transaction: %{status: @blockchain_transaction_confirmed}} = transaction
       ) do
    transaction
    |> Preloader.preload([
      :from_token,
      :to_token,
      :from_wallet,
      :to_wallet
    ])
    |> set_blockchain_wallets(:from_wallet, :from)
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: true})
    |> update_transaction(transaction, :from_blockchain_to_ledger)
  end

  defp process_with_transaction(
         :from_blockchain_to_ledger,
         transaction
       ) do
    TransactionState.transition_to(
      :from_blockchain_to_ledger,
      TransactionState.failed(),
      transaction,
      %{
        originator: %System{},
        error_code: @default_error_code,
        error_description: @default_error_description
      }
    )
  end

  # This is called for ledger to blockchain transaction before the transaction is submitted
  # to the blockchain
  defp process_with_transaction(
         :from_ledger_to_blockchain,
         %Transaction{status: @pending} = transaction
       ) do
    transaction
    |> Preloader.preload([
      :from_token,
      :to_token,
      :from_wallet,
      :to_wallet
    ])
    |> set_blockchain_wallets(:to_wallet, :to)
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

  defp process_with_transaction(:from_ledger_to_blockchain, transaction),
    do: {:error, transaction}

  defp set_blockchain_wallets(transaction, assoc, field) do
    case Map.get(transaction, field) do
      nil ->
        Map.put(transaction, assoc, %{address: transaction.from_blockchain_address, metadata: %{}})

      _ ->
        transaction
    end
  end

  #
  # Skip errored transactions and transactions already recorded in the local ledger.
  #

  defp update_transaction(
         _,
         %Transaction{local_ledger_uuid: local_ledger_uuid, error_code: error_code} = transaction,
         _
       )
       when not is_nil(local_ledger_uuid) and not is_nil(error_code) do
    {:error, transaction}
  end

  #
  # Handle transactions from blockchain to ledger
  #

  defp update_transaction(
         {:ok, ledger_transaction},
         transaction,
         :from_blockchain_to_ledger
       ) do
    TransactionState.transition_to(
      :from_blockchain_to_ledger,
      TransactionState.confirmed(),
      transaction,
      %{
        local_ledger_uuid: ledger_transaction.uuid,
        originator: %System{}
      }
    )
  end

  #
  # Handle transactions from ledger to blockchainn
  #

  defp update_transaction(
         {:ok, ledger_transaction},
         %{status: @pending} = transaction,
         :from_ledger_to_blockchain
       ) do
    TransactionState.transition_to(
      :from_ledger_to_blockchain,
      TransactionState.ledger_pending(),
      transaction,
      %{
        local_ledger_uuid: ledger_transaction.uuid,
        originator: %System{}
      }
    )
  end

  defp update_transaction(
         {:ok, _ledger_transaction},
         %{status: @ledger_pending_blockchain_confirmed} = transaction,
         :from_ledger_to_blockchain
       ) do
    TransactionState.transition_to(
      :from_ledger_to_blockchain,
      TransactionState.confirmed(),
      transaction,
      %{
        originator: %System{}
      }
    )
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
