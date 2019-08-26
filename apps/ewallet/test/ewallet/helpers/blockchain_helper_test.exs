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

defmodule EWallet.BlockchainHelperTest do
  use ExUnit.Case, async: true
  alias EWallet.BlockchainHelper

  describe "validate_blockchain_address/1" do
    test "returns :ok when given a valid blockchain address" do
      address = "0x1234567890123456789012345678901234567890"
      assert BlockchainHelper.validate_blockchain_address(address) == :ok
    end

    test "returns an :invalid_blockchain_address error when given an invalid address" do
      address = "0xinvalid"
      assert BlockchainHelper.validate_blockchain_address(address) == {:error, :invalid_blockchain_address}
    end
  end

  describe "identifier/0" do
    test "returns the blockchain identifier" do
      assert BlockchainHelper.identifier() |> IO.inspect(label: "identifier")
    end
  end

  describe "call/4" do
    test "returns result from calling the default blockchain adapter and default node adapter" do
      assert BlockchainHelper.call(:get_block, 1) == {:ok, nil}
    end
  end

  describe "adapter/0" do
    test "returns the current blockchain adapter" do
      assert BlockchainHelper.adapter() == EthBlockchain.Adapter
    end
  end

  describe "invalid_erc20_contract_address/0" do
    test "returns an invalid erc20 contract address" do
      assert BlockchainHelper.invalid_erc20_contract_address() == "0x9080682a37961d3c814464e7ada1c7e1b4638a27"
    end
  end
end
