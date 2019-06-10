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

defmodule EthBlockchain.AdapterTest do
  use EthBlockchain.EthBlockchainCase
  alias EthBlockchain.Adapter

  describe "call/3" do
    test "delegates call to the adapter", state do
      dumb_resp1 =
        Adapter.call(
          :dumb,
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:pid]
        )

      dumb_resp2 =
        Adapter.call(
          {:dumb, "balance"},
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:pid]
        )

      assert {:ok, %{state[:addr_1] => 123, state[:addr_2] => 123, state[:addr_3] => 123}} ==
               dumb_resp1

      assert {:ok, %{state[:addr_1] => 123, state[:addr_2] => 123, state[:addr_3] => 123}} ==
               dumb_resp2
    end

    test "shutdowns the worker once finished handling tasks", state do
      {:ok, _} =
        Adapter.call(
          :dumb,
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:pid]
        )

      {:ok, _} =
        Adapter.call(
          {:dumb, "balance"},
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:pid]
        )

      {:ok, _} =
        Adapter.call(
          :dumb,
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:pid]
        )

      childrens = DynamicSupervisor.which_children(state[:supervisor])
      assert childrens == []
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Adapter.call(
                 :foobar,
                 {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]],
                  nil, "latest"},
                 state[:pid]
               )
    end
  end
end
