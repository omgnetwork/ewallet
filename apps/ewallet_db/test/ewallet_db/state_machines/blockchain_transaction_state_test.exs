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

defmodule EWalletDB.BlockchainTransactionStateTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.BlockchainTransactionState
  alias ActivityLogger.System

  def test_successful_state_transition(from_state, to_state, attrs \\ %{}) do
    blockchain_transaction = insert(:blockchain_transaction_rootchain, status: from_state)
    assert blockchain_transaction.status == from_state

    {:ok, blockchain_transaction} =
      BlockchainTransactionState.transition_to(
        to_state,
        blockchain_transaction,
        Map.merge(
          %{
            originator: %System{}
          },
          attrs
        )
      )

    assert blockchain_transaction.status == to_state
  end

  def test_failed_state_transition(from_state, to_state, attrs \\ %{}) do
    blockchain_transaction = insert(:blockchain_transaction_rootchain, status: from_state)
    assert blockchain_transaction.status == from_state

    {:error, error} =
      BlockchainTransactionState.transition_to(
        to_state,
        blockchain_transaction,
        Map.merge(
          %{
            originator: %System{}
          },
          attrs
        )
      )

    assert error == :invalid_state_transition
  end

  describe "transition_to/3" do
    test "transition from submitted to pending_confirmations successfully" do
      test_successful_state_transition(
        BlockchainTransactionState.submitted(),
        BlockchainTransactionState.pending_confirmations(),
        %{
          block_number: 1
        }
      )
    end

    test "transition from submitted to confirmed successfully" do
      test_successful_state_transition(
        BlockchainTransactionState.submitted(),
        BlockchainTransactionState.confirmed(),
        %{
          block_number: 1,
          confirmed_at_block_number: 1
        }
      )
    end

    test "transition from submitted to failed successfully" do
      test_successful_state_transition(
        BlockchainTransactionState.submitted(),
        BlockchainTransactionState.failed(),
        %{
          error: "some error"
        }
      )
    end

    test "transition from pending_confirmations to confirmed successfully" do
      test_successful_state_transition(
        BlockchainTransactionState.pending_confirmations(),
        BlockchainTransactionState.confirmed(),
        %{
          block_number: 1,
          confirmed_at_block_number: 10
        }
      )
    end

    test "transition from pending_confirmations to failed successfully" do
      test_successful_state_transition(
        BlockchainTransactionState.pending_confirmations(),
        BlockchainTransactionState.failed(),
        %{
          error: "some error"
        }
      )
    end

    test "transition from pending_confirmations to pending_confirmations successfully" do
      test_successful_state_transition(
        BlockchainTransactionState.pending_confirmations(),
        BlockchainTransactionState.pending_confirmations(),
        %{
          block_number: 2
        }
      )
    end

    test "returns error when transitioning from confirmed to other statuses" do
      test_failed_state_transition(
        BlockchainTransactionState.confirmed(),
        BlockchainTransactionState.failed()
      )
    end

    test "returns error when transitioning from failed to other statuses" do
      test_failed_state_transition(
        BlockchainTransactionState.failed(),
        BlockchainTransactionState.confirmed()
      )
    end
  end
end
