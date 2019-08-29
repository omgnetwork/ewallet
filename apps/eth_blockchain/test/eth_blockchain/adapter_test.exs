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
  alias EthBlockchain.{Adapter, TransactionListener}

  describe "eth_call/2" do
    test "delegates get_balances call to the adapter", state do
      dumb_resp1 =
        Adapter.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          eth_node_adapter: :dumb,
          eth_node_adapter_pid: state[:pid]
        )

      dumb_resp2 =
        Adapter.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          eth_node_adapter: {:dumb, "balance"},
          eth_node_adapter_pid: state[:pid]
        )

      assert {:ok, ["0x7B", "0x7B", "0x7B"]} == dumb_resp1
      assert {:ok, ["0x7B", "0x7B", "0x7B"]} == dumb_resp2
    end

    test "shutdowns the worker once finished handling tasks", state do
      {:ok, _} =
        Adapter.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          eth_node_adapter: :dumb,
          eth_node_adapter_pid: state[:pid]
        )

      {:ok, _} =
        Adapter.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          eth_node_adapter: {:dumb, "balance"},
          eth_node_adapter_pid: state[:pid]
        )

      {:ok, _} =
        Adapter.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          eth_node_adapter: :dumb,
          eth_node_adapter_pid: state[:pid]
        )

      childrens = DynamicSupervisor.which_children(state[:supervisor])
      assert childrens == []
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Adapter.eth_call(
                 {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]],
                  nil, "latest"},
                 eth_node_adapter: :foobar,
                 eth_node_adapter_pid: state[:pid]
               )
    end
  end

  describe "subscribe/5" do
    test "returns :ok" do
      assert Adapter.subscribe(:transaction, "0x123456789", self()) == :ok
    end
  end

  describe "unsubscribe/3" do
    test "unsubscribes the given subscriber from the registry for the given transaction hash" do
      :ok = Adapter.subscribe(:transaction, "0x123456789", self())
      assert Adapter.unsubscribe(:transaction, "0x123456789", self()) == :ok
    end
  end

  describe "lookup_listener/1" do
    test "returns the list of subscribers for the given transaction hash" do
      :ok = Adapter.subscribe(:transaction, "0x123456789", self())
      {res, listener} = Adapter.lookup_listener("0x123456789")

      assert res == :ok
      assert listener.listener == TransactionListener
      assert is_pid(listener.pid)
    end
  end
end
