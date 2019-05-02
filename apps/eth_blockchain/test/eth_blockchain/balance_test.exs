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

defmodule EthBlockchain.BalanceTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.Balance

  describe "get/1" do
    test "get wallet balances with the given adapter spec", state do
      resp = Balance.get({"0x123", ["0x01", "0x02", "0x03"]}, :mock, state[:pid])
      assert resp == {:ok, %{"0x01" => 123, "0x02" => 123, "0x03" => 123}}
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} == Balance.get({"0x123", ["0x01", "0x02"]}, :blah, state[:pid])
    end
  end
end
