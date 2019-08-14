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

defmodule EthBlockchain.BlockTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.Block

  describe "get/1" do
    test "get wallet balances with the given adapter spec", state do
      res =
        Block.get_number(
          :dumb,
          state[:pid]
        )

      assert res == 14
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Block.get_number(
                 :blah,
                 state[:pid]
               )
    end
  end

  describe "get_number/2" do
    test "returns the latest block number"
  end

  describe "get_transactions/3" do
    test "returns the list of transactions for the given block number"
    test "returns :block_not_found error if the block number is invalid"
  end
end
