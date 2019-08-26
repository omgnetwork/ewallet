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
    test "get the block with the given block number", state do
      assert Block.get(0, :dumb, state[:pid]) == {:ok, %{"transactions" => []}}
      assert Block.get(1, :dumb, state[:pid]) == {:ok, nil}
    end

    test "returns an error if no such adapter is registered", state do
      assert Block.get_number(:nonexistent_adapter, state[:pid]) == {:error, :no_handler}
    end
  end

  describe "get_number/2" do
    test "returns the latest block number", state do
      assert Block.get_number(:dumb, state[:pid]) == 14
    end
  end

  describe "get_transactions/3" do
    test "returns the list of transactions for the given block number", state do
      attrs = %{
        blk_number: 0,
        addresses: [],
        contract_addresses: []
      }

      assert Block.get_transactions(attrs, :dumb, state[:pid]) == []
    end

    test "returns :block_not_found error if the block number is invalid", state do
      attrs = %{
        blk_number: 1,
        addresses: [],
        contract_addresses: []
      }

      assert Block.get_transactions(attrs, :dumb, state[:pid]) == {:error, :block_not_found}
    end
  end
end
