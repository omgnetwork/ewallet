# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EthBlockchain.NonceRegistryTest do
  use EthBlockchain.EthBlockchainCase
  alias EthBlockchain.{NonceRegistry, DumbAdapter}

  describe "start_link/1" do
    test "starts a new server" do
      assert {:ok, pid} = NonceRegistry.start_link(name: :test_registry)
      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits with empty map" do
      assert NonceRegistry.init(:ok) == {:ok, %{}}
    end
  end

  describe "lookup/4" do
    test "starts a new nonce handler and registers it" do
      address = DumbAdapter.high_transaction_count_address()
      assert {:ok, pid} = NonceRegistry.start_link(name: :test_registry)
      {:ok, handler_pid} = NonceRegistry.lookup(address, nil, nil, pid)

      assert is_pid(handler_pid)

      assert :sys.get_state(pid) == %{
               address => handler_pid
             }

      assert GenServer.stop(handler_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end

    test "returns an already registered nonce handler" do
      address = DumbAdapter.high_transaction_count_address()
      assert {:ok, pid} = NonceRegistry.start_link(name: :test_registry)
      {:ok, handler_pid_1} = NonceRegistry.lookup(address, nil, nil, pid)
      {:ok, handler_pid_2} = NonceRegistry.lookup(address, nil, nil, pid)

      assert is_pid(handler_pid_1)
      assert handler_pid_1 == handler_pid_2

      assert :sys.get_state(pid) == %{
               address => handler_pid_1
             }

      assert GenServer.stop(handler_pid_1) == :ok
      assert GenServer.stop(pid) == :ok
    end

    test "returns an error when a nonce handler can't be started" do
      address = DumbAdapter.high_transaction_count_address()
      assert {:ok, pid} = NonceRegistry.start_link(name: :test_registry)
      assert NonceRegistry.lookup(address, FakeAdapter, nil, pid) == {:error, :no_handler}
      assert :sys.get_state(pid) == %{}
    end

    test "handles different adapters properly" do
      address = DumbAdapter.high_transaction_count_address()
      assert {:ok, pid} = NonceRegistry.start_link(name: :test_registry)
      {:ok, handler_pid_1} = NonceRegistry.lookup(address, :dumb, nil, pid)
      {:ok, handler_pid_2} = NonceRegistry.lookup(address, nil, nil, pid)

      assert is_pid(handler_pid_1)
      assert is_pid(handler_pid_2)
      assert handler_pid_1 == handler_pid_2

      assert :sys.get_state(pid) == %{
               address => handler_pid_1
             }

      assert GenServer.stop(handler_pid_1) == :ok
      assert GenServer.stop(pid) == :ok
    end
  end
end
