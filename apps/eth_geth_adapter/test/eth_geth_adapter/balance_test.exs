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

defmodule EthGethAdapter.BalanceTest do
  use ExUnit.Case

  alias EthGethAdapter.Balance

  describe "get/3" do
    test "raises an error if a contract address is invalid" do
      address = "0x54e0588607dcec6c0b36fca1154a57814a913591"
      contract_addresses = ["0x48b91d5f363892592bf836777dc73b54a10b72ae", "0x123"]

      assert_raise ArgumentError, "0x123 is not a valid contract address", fn ->
        Balance.get(address, contract_addresses, nil)
      end
    end
  end
end
