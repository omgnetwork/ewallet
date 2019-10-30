# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.BlockchainStateGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.BlockchainStateGate
  alias EWalletDB.BlockchainState

  @identifier "some_blockchain_identifier"

  setup do
    # As test default, the blockchain state's block number is higher than the latest transaction's
    {:ok, _} = BlockchainState.insert(%{identifier: @identifier, blk_number: 555_555})
    _ = insert(:blockchain_transaction_rootchain, rootchain_identifier: @identifier, block_number: 111_111)

    :ok
  end

  describe "get_last_synced_blk_number/1" do
    test "returns the overall block number when the overall block is higher" do
      assert BlockchainStateGate.get_last_synced_blk_number(@identifier) == 555_555
      assert BlockchainState.get(@identifier).blk_number == 555_555
    end

    test "returns the latest transaction's block number when it is higher" do
      assert BlockchainStateGate.get_last_synced_blk_number(@identifier) == 555_555

      _ = insert(:blockchain_transaction_rootchain, rootchain_identifier: @identifier, block_number: 999_999)

      assert BlockchainStateGate.get_last_synced_blk_number(@identifier) == 999_999
      assert BlockchainState.get(@identifier).blk_number == 999_999
    end
  end
end
