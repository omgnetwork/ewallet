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

defmodule EWallet.BlockchainTransactionState do
  @moduledoc """
  State machine module for blockchain transactions.
  """
  # TODO: pure blockchain [:pending, :submitted, :pending_confirmations, :confirmed]
  # TODO: local + blockchain [:pending, :locally_stored, :submitted,
  #                           :pending_confirmations, :confirmed]
  alias EWalletDB.{Transaction, Repo}

  def transition_to(:submitted, transaction, tx_hash, originator) do
    transaction
    |> Transaction.submitted_changeset(%{
      status: "submitted",
      blockchain_tx_hash: tx_hash,
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  def transition_to(:pending_confirmations, transaction, confirmations_count, originator) do
    transaction
    |> Transaction.confirmations_changeset(%{
      status: "pending_confirmations",
      confirmations_count: confirmations_count,
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  def transition_to(:blockchain_confirmed, transaction, confirmations_count, originator) do
    transaction
    |> Transaction.confirmations_changeset(%{
      status: "blockchain_confirmed",
      confirmations_count: confirmations_count,
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  def transition_to(:local_confirmed, %{status: "pending"} = transaction, ledger_transaction, originator) do
    Transaction.confirm(transaction, ledger_transaction.uuid, originator)
  end

  def transition_to(:local_confirmed, %{status: "pending_recording"} = transaction, ledger_transaction, originator) do
    transaction
    |> Transaction.confirmations_changeset(%{
      status: "recorded",
      local_ledger_uuid: ledger_transaction.uuid,
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  def transition_to(:confirmed, transaction, confirmations_count, originator) do
    IO.inspect("Confirmed!")
    IO.inspect(confirmations_count)
    transaction
    |> Transaction.confirmations_changeset(%{
      status: "confirmed",
      confirmations_count: confirmations_count,
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  def transition_to(:confirmed, %{status: "recorded"} = transaction, originator) do
    transaction
    |> Transaction.confirmations_changeset(%{
      status: "confirmed",
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  def transition_to(:failed, transaction, code, description, originator) do
    Transaction.fail(transaction, code, description, originator)
  end
end
