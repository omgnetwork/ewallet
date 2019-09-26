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

defmodule EWalletDB.BlockchainTransactionState do
  @moduledoc """
  State machine module for blockchain transactions.
  """
  alias EWalletDB.{BlockchainTransaction, Repo}

  @submitted "submitted"
  @pending_confirmations "pending_confirmations"
  @confirmed "confirmed"
  @failed "failed"

  # For each state, we have {[cast_fields], [required_fields]}
  @attrs %{
    @submitted => {[], []},
    @pending_confirmations => {[:block_number], [:block_number]},
    # Note: We need to have `block_number` in confirmed as well in case it goes from
    # submitted directly to confirmed
    @confirmed =>
      {[:block_number, :confirmed_at_block_number], [:block_number, :confirmed_at_block_number]},
    @failed => {[:error], [:error]}
  }

  @states %{
    @submitted => [@pending_confirmations, @confirmed, @failed],
    @pending_confirmations => [@pending_confirmations, @confirmed, @failed],
    @confirmed => [@confirmed],
    @confirmed => [],
    @failed => []
  }

  @statuses [
    @submitted,
    @pending_confirmations,
    @confirmed,
    @failed
  ]

  @doc """
  Returns the "submitted" status's string representation.

  A blockchain transaction enters the "submitted" status when the transaction has been submitted
  to the blockchain. A transaction gains this status immediately after a succfessful submission
  with zero block confirmation.
  """
  def submitted, do: @submitted

  @doc """
  Returns the "pending_confirmations" status's string representation.

  A blockchain transaction enters the "pending_confirmations" status when the transaction has been submitted
  to the blockchain, and some confirmations have been received. However, the number of confirmations
  have not reached the threshold to be considered a successful transaction.
  """
  def pending_confirmations, do: @pending_confirmations

  @doc """
  Returns the "confirmed" status's string representation.

  A blockchain transaction enters the "confirmed" status when the number of confirmations reaches
  the threshold to be considered successful.
  """
  def confirmed, do: @confirmed

  @doc """
  Returns the "failed" status's string representation.

  A blockchain transaction enters the "failed" status if there was an issue during the submission to
  the blockchain.
  """
  def failed, do: @failed

  @doc """
  Returns the list of all possible string representations of blockchain transaction statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns a map containing all possible transitions.
  """
  def states, do: @states

  def transition_to(new_state, %{status: state} = blockchain_transaction, attrs) do
    with next_states when is_list(next_states) <- @states[state] || :state_not_found,
         true <- Enum.member?(next_states, new_state) || :invalid_state_transition do
      {cast_fields, required_fields} = @attrs[new_state]
      attrs = Map.merge(attrs, %{status: new_state})

      blockchain_transaction
      |> BlockchainTransaction.state_changeset(attrs, [:status | cast_fields], [
        :status | required_fields
      ])
      |> Repo.update_record_with_activity_log()
    else
      code when is_atom(code) ->
        {:error, code}
    end
  end
end
