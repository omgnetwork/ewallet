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
      resp =
        Balance.get(
          {state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]]},
          :dumb,
          state[:pid]
        )

      assert resp == {:ok, %{state[:addr_1] => 123, state[:addr_2] => 123, state[:addr_3] => 123}}
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Balance.get({state[:addr_0], [state[:addr_1], state[:addr_2]]}, :blah, state[:pid])
    end
  end
end
