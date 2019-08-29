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

defmodule EthBlockchain.ClientTest do
  use EthBlockchain.EthBlockchainCase, async: true
  alias EthBlockchain.Client

  describe "get_eth_syncing/0" do
    test "returns the syncing status", state do
      # The result is mocked in EthBlockchain.DumbAdapter.handle_call({:get_eth_syncing},...)
      assert Client.get_eth_syncing(
               eth_node_adapter: :dumb,
               eth_node_adapter_pid: state[:pid]
             ) == {:ok, false}
    end

    test "returns an error if no such adapter is registered", state do
      assert Client.get_eth_syncing(
               eth_node_adapter: :blah,
               eth_node_adapter_pid: state[:pid]
             ) == {:error, :no_handler}
    end
  end

  describe "get_client_version/0" do
    test "returns the client version", state do
      # The result is mocked in EthBlockchain.DumbAdapter.handle_call({:get_client_version},...)
      assert Client.get_client_version(
               eth_node_adapter: :dumb,
               eth_node_adapter_pid: state[:pid]
             ) ==
               {:ok, "DumbAdapter/v4.2.0-c999068/linux/go1.9.2"}
    end

    test "returns an error if no such adapter is registered", state do
      assert Client.get_client_version(
               eth_node_adapter: :blah,
               eth_node_adapter_pid: state[:pid]
             ) == {:error, :no_handler}
    end
  end

  describe "get_network_id/0" do
    test "returns the network id", state do
      # The result is mocked in EthBlockchain.DumbAdapter.handle_call({:get_network_id},...)
      assert Client.get_network_id(
               eth_node_adapter: :dumb,
               eth_node_adapter_pid: state[:pid]
             ) == {:ok, "99"}
    end

    test "returns an error if no such adapter is registered", state do
      assert Client.get_network_id(
               eth_node_adapter: :blah,
               eth_node_adapter_pid: state[:pid]
             ) == {:error, :no_handler}
    end
  end

  describe "get_peer_count/0" do
    test "returns the number of peers", state do
      # The result is mocked in EthBlockchain.DumbAdapter.handle_call({:get_peer_count},...)
      assert Client.get_peer_count(
               eth_node_adapter: :dumb,
               eth_node_adapter_pid: state[:pid]
             ) == {:ok, 42}
    end

    test "returns an error if no such adapter is registered", state do
      assert Client.get_peer_count(
               eth_node_adapter: :blah,
               eth_node_adapter_pid: state[:pid]
             ) == {:error, :no_handler}
    end
  end
end
