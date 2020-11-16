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

defmodule EthBlockchain.AdapterServerTest do
  use EthBlockchain.EthBlockchainCase
  alias EthBlockchain.AdapterServer

  describe "eth_call/2" do
    test "delegates get_balances call to the adapter", state do
      dumb_resp1 =
        AdapterServer.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:adapter_opts]
        )

      dumb_resp2 =
        AdapterServer.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:adapter_opts]
        )

      assert {:ok, ["0x7B", "0x7B", "0x7B"]} == dumb_resp1
      assert {:ok, ["0x7B", "0x7B", "0x7B"]} == dumb_resp2
    end

    test "shutdowns the worker once finished handling tasks", state do
      {:ok, _} =
        AdapterServer.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:adapter_opts]
        )

      {:ok, _} =
        AdapterServer.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:adapter_opts]
        )

      {:ok, _} =
        AdapterServer.eth_call(
          {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]], nil,
           "latest"},
          state[:adapter_opts]
        )

      childrens = DynamicSupervisor.which_children(state[:supervisor])
      assert childrens == []
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               AdapterServer.eth_call(
                 {:get_balances, state[:addr_0], [state[:addr_1], state[:addr_2], state[:addr_3]],
                  nil, "latest"},
                 eth_node_adapter: :foobar,
                 eth_node_adapter_pid: state[:adapter_opts][:eth_node_adapter_pid]
               )
    end
  end

  describe "childchain_call/2" do
    test "delegates get_contract_address call to the adapter", state do
      dumb_resp1 =
        AdapterServer.childchain_call(
          {:get_contract_address},
          state[:adapter_opts]
        )

      dumb_resp2 =
        AdapterServer.childchain_call(
          {:get_contract_address},
          state[:adapter_opts]
        )

      assert {:ok, "0xc673e4ffcb8464faff908a6804fe0e635af0ea2f"} == dumb_resp1
      assert {:ok, "0xc673e4ffcb8464faff908a6804fe0e635af0ea2f"} == dumb_resp2
    end

    test "shutdowns the worker once finished handling tasks", state do
      {:ok, _} =
        AdapterServer.childchain_call(
          {:get_contract_address},
          state[:adapter_opts]
        )

      {:ok, _} =
        AdapterServer.childchain_call(
          {:get_contract_address},
          state[:adapter_opts]
        )

      {:ok, _} =
        AdapterServer.childchain_call(
          {:get_contract_address},
          state[:adapter_opts]
        )

      childrens = DynamicSupervisor.which_children(state[:supervisor])
      assert childrens == []
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               AdapterServer.childchain_call(
                 {:get_contract_address},
                 cc_node_adapter: :foobar,
                 cc_node_adapter_pid: state[:adapter_opts][:cc_node_adapter_pid]
               )
    end
  end
end
