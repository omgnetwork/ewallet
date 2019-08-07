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

  describe "transition_to/4 for local-to-local transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to confirmed successfully"
    test "transition from pending to failed successfully"
    test "returns error when transitioning from confirmed to other statuses"
    test "returns error when transitioning from failed to other statuses"
  end

  describe "transition_to/4 for blockchain-to-ewallet transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to pending_confirmations successfully"
    test "transition from pending to blockchain_confirmed successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "returns error when transitioning from confirmed to other statuses"
  end

  describe "transition_to/4 for ewallet-to-blockchain transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to blockchain_submitted successfully"
    test "transition from blockchain_submitted to pending_confirmations successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "returns error when transitioning from confirmed to other statuses"
  end

  describe "transition_to/4 for blockchain-to-local transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to pending_confirmations successfully"
    test "transition from pending to blockchain_confirmed successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "transition from blockchain_confirmed to failed successfully"
    test "returns error when transitioning from confirmed to other statuses"
    test "returns error when transitioning from failed to other statuses"
  end

  describe "transition_to/4 for local-to-blockchain transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to ledger_pending successfully"
    test "transition from pending to failed successfully"
    test "transition from ledger_pending to blockchain_submitted successfully"
    test "transition from blockchain_submitted to pending_confirmations successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "returns error when transitioning from confirmed to other statuses"
  end
end
