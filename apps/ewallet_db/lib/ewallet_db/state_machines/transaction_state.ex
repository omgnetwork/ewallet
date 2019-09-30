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

defmodule EWalletDB.TransactionState do
  @moduledoc """
  State machine module for transactions.
  """
  alias EWalletDB.Repo

  @pending "pending"
  @confirmed "confirmed"
  @failed "failed"
  @blockchain_failed "blockchain_failed"
  @blockchain_submitted "blockchain_submitted"
  @ledger_pending "ledger_pending"
  @pending_confirmations "pending_confirmations"
  @ledger_pending_blockchain_confirmed "ledger_pending_blockchain_confirmed"
  @blockchain_confirmed "blockchain_confirmed"

  # For each state, we have {[cast_fields], [required_fields]}
  @attrs %{
    @pending => {[], []},
    @confirmed => {[:local_ledger_uuid], []},
    @failed => {[:error_code, :error_description, :error_data], [:error_code]},
    @blockchain_failed => {[:error_code, :error_description, :error_data], [:error_code]},
    @blockchain_submitted => {[:blockchain_tx_hash], [:blockchain_tx_hash]},
    @ledger_pending => {[], []},
    @pending_confirmations => {[:confirmations_count, :blk_number], [:confirmations_count]},
    @ledger_pending_blockchain_confirmed => {[:confirmations_count], [:confirmations_count]},
    @blockchain_confirmed => {[:confirmations_count], [:confirmations_count]}
  }

  @states %{
    # Local Transactions
    # pending -> confirmed || failed
    from_ledger_to_ledger: %{
      @pending => [@confirmed, @failed],
      @confirmed => [],
      @failed => []
    },
    # From Blockchain Transactions
    # pending -> pending_confirmations -> blockchain_confirmed -> confirmed
    from_blockchain_to_ewallet: %{
      @pending => [@pending_confirmations, @blockchain_confirmed],
      @pending_confirmations => [@pending_confirmations, @blockchain_confirmed],
      @blockchain_confirmed => [@confirmed],
      @confirmed => []
    },
    # To Blockchain Transactions
    # pending -> blockchain_submitted -> pending_confirmations -> blockchain_confirmed -> confirmed
    from_ewallet_to_blockchain: %{
      @pending => [@blockchain_submitted],
      @blockchain_submitted => [@pending_confirmations, @blockchain_confirmed],
      @pending_confirmations => [@pending_confirmations, @blockchain_confirmed],
      @blockchain_confirmed => [@confirmed],
      @confirmed => []
    },
    # Blockchain -> Local transactions
    # pending -> pending_confirmations ||> blockchain_confirmed -> confirmed || failed
    from_blockchain_to_ledger: %{
      @pending => [@pending_confirmations, @blockchain_confirmed],
      @pending_confirmations => [@pending_confirmations, @blockchain_confirmed],
      @blockchain_confirmed => [@confirmed, @failed],
      @confirmed => [],
      @failed => []
    },
    # Local -> Blockchain transactions
    # pending -> ledger_pending || failed -> blockchain_submitted -> pending_confirmations ->
    # -> ledger_pending_blockchain_confirmed -> confirmed
    from_ledger_to_blockchain: %{
      @pending => [@ledger_pending, @failed],
      @ledger_pending => [@blockchain_submitted, @blockchain_failed],
      @blockchain_submitted => [
        @pending_confirmations,
        @blockchain_confirmed,
        @blockchain_failed
      ],
      @pending_confirmations => [
        @pending_confirmations,
        @ledger_pending_blockchain_confirmed,
        @blockchain_failed
      ],
      @ledger_pending_blockchain_confirmed => [@confirmed],
      @confirmed => []
    }
  }

  @statuses [
    @pending,
    @confirmed,
    @failed,
    @blockchain_submitted,
    @ledger_pending,
    @pending_confirmations,
    @blockchain_confirmed,
    @ledger_pending_blockchain_confirmed
  ]

  @doc """
  Returns "pending" status's string representation.

  A transaction enters the "pending" status at the very beginning of the transaction flow,
  when it is not yet recorded by the local ledger, and if also applicable,
  not yet recorded by the blockchain.
  """
  def pending, do: @pending

  @doc """
  Returns the "confirmed" status's string representation.

  A transaction enters the "confirmed" status when it is fully complete. That is,
  it is successfully recorded by the local ledger, and if also applicable, by the blockchain.
  """
  def confirmed, do: @confirmed

  @doc """
  Returns the "failed" status's string representation.

  A transaction enters the "failed" status when it failed at some point. This could be a failure
  at the local ledger or blockchain level. No further actions can be performed on this transaction.
  """
  def failed, do: @failed

  @doc """
  Returns the "ledger_pending" status's string representation.

  A transaction enters the "ledger_pending" status when the transaction has been recorded into
  the local ledger, but the ledger entries are marked with "pending" status. This means this
  transaction may be reverted if the blockchain submission or confirmation is unsuccessful.
  """
  def ledger_pending, do: @ledger_pending

  @doc """
  Returns the "blockchain_submitted" status's string representation.

  A transaction enters the "blockchain_submitted" status when the transaction has been submitted
  to the blockchain. A transaction gains this status immediately after a succfessful submission
  with zero block confirmation.
  """
  def blockchain_submitted, do: @blockchain_submitted

  @doc """
  Returns the "pending_confirmations" status's string representation.

  A transaction enters the "pending_confirmations" status when the transaction has been submitted
  to the blockchain, and some confirmations have been received. However, the number of confirmations
  have not reached the threshold to be considered a successful transaction.
  """
  def pending_confirmations, do: @pending_confirmations

  @doc """
  Returns the "blockchain_confirmed" status's string representation.

  A transaction enters the "blockchain_confirmed" status when the number of confirmations reach
  the threshold to be considered successful. This status is used for incoming transactions
  where the transaction is recorded to the ledger only after the blockchain transaction is
  confirmed. Outgoing transactions use `ledger_pending_blockchain_confirmed/0` instead.
  """
  def blockchain_confirmed, do: @blockchain_confirmed

  @doc """
  Returns the "ledger_pending_blockchain_confirmed" status's string representation.

  A transaction enters the "ledger_pending_blockchain_confirmed" status when the number of confirmations reach
  the threshold to be considered successful. This status is used for outgoing transactions
  where the transaction is recorded to the ledger with "pending" entries before the blockchain
  transaction is confirmed. Incoming transactions use `blockchain_confirmed/0` instead.
  """
  def ledger_pending_blockchain_confirmed, do: @ledger_pending_blockchain_confirmed

  @doc """
  Returns the list of all possible string representations of transaction statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns a map containing all possible transitions for each transaction flow.
  """
  def states, do: @states

  def transition_to(flow_name, new_state, %{status: state} = transaction, attrs) do
    with flow when is_map(flow) <- @states[flow_name] || :state_flow_not_found,
         next_states when is_list(next_states) <- flow[state] || :state_not_found,
         true <- Enum.member?(next_states, new_state) || :invalid_state_transition do
      {cast_fields, required_fields} = @attrs[new_state]
      attrs = Map.merge(attrs, %{status: new_state})

      transaction
      |> Transaction.state_changeset(attrs, [:status | cast_fields], [:status | required_fields])
      |> Repo.update_record_with_activity_log()
    else
      code when is_atom(code) ->
        {:error, code}
    end
  end
end
