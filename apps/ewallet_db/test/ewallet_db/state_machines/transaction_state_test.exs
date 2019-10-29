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

defmodule EWalletDB.TransactionStateTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.TransactionState
  alias ActivityLogger.System

  def test_successful_state_transition(flow, from_state, to_state, attrs \\ %{}) do
    transaction = insert(:transaction, status: from_state)
    assert transaction.status == from_state

    {:ok, transaction} =
      TransactionState.transition_to(
        flow,
        to_state,
        transaction,
        Map.merge(
          %{
            originator: %System{}
          },
          attrs
        )
      )

    assert transaction.status == to_state
  end

  def test_failed_state_transition(flow, from_state, to_state, attrs \\ %{}) do
    transaction = insert(:transaction, status: from_state)
    assert transaction.status == from_state

    {:error, error} =
      TransactionState.transition_to(
        flow,
        to_state,
        transaction,
        Map.merge(
          %{
            originator: %System{}
          },
          attrs
        )
      )

    assert error == :invalid_state_transition
  end

  describe "transition_to/4 for from_ledger_to_ledger transactions" do
    test "transition from pending to confirmed successfully" do
      test_successful_state_transition(
        :from_ledger_to_ledger,
        TransactionState.pending(),
        TransactionState.confirmed(),
        %{}
      )
    end

    test "transition from pending to failed successfully" do
      test_successful_state_transition(
        :from_ledger_to_ledger,
        TransactionState.pending(),
        TransactionState.failed(),
        %{error_code: "code"}
      )
    end

    test "returns error when transitioning from confirmed to other statuses" do
      test_failed_state_transition(
        :from_ledger_to_ledger,
        TransactionState.confirmed(),
        TransactionState.failed(),
        %{error_code: "code"}
      )
    end

    test "returns error when transitioning from failed to other statuses" do
      test_failed_state_transition(
        :from_ledger_to_ledger,
        TransactionState.failed(),
        TransactionState.confirmed(),
        %{error_code: "code"}
      )
    end
  end

  describe "transition_to/4 for from_blockchain_to_ewallet transactions" do
    test "transition from pending to confirmed successfully" do
      test_successful_state_transition(
        :from_blockchain_to_ewallet,
        TransactionState.pending(),
        TransactionState.confirmed()
      )
    end

    test "transition from pending to failed successfully" do
      test_successful_state_transition(
        :from_blockchain_to_ewallet,
        TransactionState.pending(),
        TransactionState.failed(),
        %{
          error_code: "error"
        }
      )
    end

    test "returns error when transitioning from confirmed to other statuses" do
      test_failed_state_transition(
        :from_blockchain_to_ewallet,
        TransactionState.confirmed(),
        TransactionState.failed(),
        %{
          error_code: "error"
        }
      )
    end
  end

  describe "transition_to/4 for ewallet-to-blockchain transactions" do
    test "transition from pending to blockchain_submitted successfully" do
      test_successful_state_transition(
        :from_ewallet_to_blockchain,
        TransactionState.pending(),
        TransactionState.blockchain_submitted(),
        %{
          blockchain_transaction_uuid: insert(:blockchain_transaction_rootchain).uuid
        }
      )
    end

    test "transition from blockchain_submitted to confirmed successfully" do
      test_successful_state_transition(
        :from_ewallet_to_blockchain,
        TransactionState.blockchain_submitted(),
        TransactionState.confirmed()
      )
    end

    test "transition from blockchain_submitted to failed successfully" do
      test_successful_state_transition(
        :from_ewallet_to_blockchain,
        TransactionState.blockchain_submitted(),
        TransactionState.failed(),
        %{
          error_code: "error"
        }
      )
    end

    test "returns error when transitioning from confirmed to other statuses" do
      test_failed_state_transition(
        :from_ewallet_to_blockchain,
        TransactionState.confirmed(),
        TransactionState.failed(),
        %{
          error_code: "error"
        }
      )
    end
  end

  describe "transition_to/4 for from_blockchain_to_ledger transactions" do
    test "transition from pending to confirmed successfully" do
      test_successful_state_transition(
        :from_blockchain_to_ledger,
        TransactionState.pending(),
        TransactionState.confirmed()
      )
    end

    test "transition from pending to failed successfully" do
      test_successful_state_transition(
        :from_blockchain_to_ledger,
        TransactionState.pending(),
        TransactionState.failed(),
        %{
          error_code: "error"
        }
      )
    end

    test "returns error when transitioning from confirmed to other statuses" do
      test_failed_state_transition(
        :from_blockchain_to_ledger,
        TransactionState.confirmed(),
        TransactionState.pending()
      )
    end

    test "returns error when transitioning from failed to other statuses" do
      test_failed_state_transition(
        :from_blockchain_to_ledger,
        TransactionState.failed(),
        TransactionState.confirmed()
      )
    end
  end

  describe "transition_to/4 for local-to-blockchain transactions" do
    test "transition from pending to ledger_pending successfully" do
      test_successful_state_transition(
        :from_ledger_to_blockchain,
        TransactionState.pending(),
        TransactionState.ledger_pending(),
        %{
          local_ledger_uuid: "123"
        }
      )
    end

    test "transition from pending to failed successfully" do
      test_successful_state_transition(
        :from_ledger_to_blockchain,
        TransactionState.pending(),
        TransactionState.failed(),
        %{
          error_code: "error"
        }
      )
    end

    test "transition from ledger_pending to blockchain_submitted successfully" do
      test_successful_state_transition(
        :from_ledger_to_blockchain,
        TransactionState.ledger_pending(),
        TransactionState.blockchain_submitted(),
        %{
          blockchain_transaction_uuid: insert(:blockchain_transaction_rootchain).uuid
        }
      )
    end

    test "transition from blockchain_submitted to pending_confirmations successfully" do
      test_successful_state_transition(
        :from_ledger_to_blockchain,
        TransactionState.blockchain_submitted(),
        TransactionState.failed(),
        %{
          error_code: "error"
        }
      )
    end

    test "transition from blockchain_submitted to blockchain_confirmed successfully" do
      test_successful_state_transition(
        :from_ledger_to_blockchain,
        TransactionState.blockchain_submitted(),
        TransactionState.ledger_pending_blockchain_confirmed()
      )
    end

    test "transition from blockchain_confirmed to confirmed successfully" do
      test_successful_state_transition(
        :from_ledger_to_blockchain,
        TransactionState.ledger_pending_blockchain_confirmed(),
        TransactionState.confirmed()
      )
    end

    test "returns error when transitioning from confirmed to other statuses" do
      test_failed_state_transition(
        :from_ledger_to_blockchain,
        TransactionState.confirmed(),
        TransactionState.ledger_pending_blockchain_confirmed()
      )
    end
  end
end
