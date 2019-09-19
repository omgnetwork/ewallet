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

defmodule EthBlockchain.BlockchainRegistryTest do
  use EthBlockchain.EthBlockchainCase
  alias EthBlockchain.{BlockchainRegistry, DumbListener}

  describe "start_link/1" do
    test "starts a new server" do
      assert {:ok, pid} = BlockchainRegistry.start_link(name: :test_registry)
      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits with empty map" do
      assert BlockchainRegistry.init(:ok) == {:ok, %{}}
    end
  end

  describe "start_listener/3" do
    test "registers a listener and do a lookup" do
      assert {:ok, pid} = BlockchainRegistry.start_link(name: :test_registry)

      :ok =
        BlockchainRegistry.start_listener(DumbListener, %{id: "some_blockchain_identifier"}, pid)

      assert {:ok, %{listener: DumbListener, pid: listener_pid}} =
               BlockchainRegistry.lookup("some_blockchain_identifier", pid)

      assert is_pid(listener_pid)

      assert GenServer.stop(listener_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "stop_listener/2" do
    test "stops the listener" do
      assert {:ok, pid} = BlockchainRegistry.start_link(name: :test_registry)

      :ok =
        BlockchainRegistry.start_listener(DumbListener, %{id: "some_blockchain_identifier"}, pid)

      {:ok, %{pid: listener_pid}} = BlockchainRegistry.lookup("some_blockchain_identifier", pid)
      assert Process.alive?(listener_pid)

      # Link to the process so this test is notified when it exits
      ref = Process.monitor(listener_pid)

      :ok = BlockchainRegistry.stop_listener("some_blockchain_identifier", pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          refute Process.alive?(listener_pid)
      after
        1_000 ->
          refute Process.alive?(listener_pid)
      end

      assert GenServer.stop(pid) == :ok
    end
  end

  describe "subscribe/3" do
    test "subscribe a process to the given listener based on id" do
      id = "some_blockchain_identifier"
      assert {:ok, pid} = BlockchainRegistry.start_link(name: :test_registry)
      :ok = BlockchainRegistry.start_listener(DumbListener, %{id: id}, pid)

      assert {:ok, %{listener: DumbListener, pid: listener_pid}} =
               BlockchainRegistry.lookup(id, pid)

      assert is_pid(listener_pid)

      :ok = BlockchainRegistry.subscribe(id, "fake_pid", pid)
      state = :sys.get_state(listener_pid)

      assert state == %{id: id, subscribers: ["fake_pid"], registry: pid}

      assert GenServer.stop(listener_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "unsubscribe/3" do
    test "unsubscribe a process from the given listener based on id and stops it" do
      id = "some_blockchain_identifier"
      assert {:ok, pid} = BlockchainRegistry.start_link(name: :test_registry)
      :ok = BlockchainRegistry.start_listener(DumbListener, %{id: id}, pid)

      assert {:ok, %{listener: DumbListener, pid: listener_pid}} =
               BlockchainRegistry.lookup(id, pid)

      assert is_pid(listener_pid)

      :ok = BlockchainRegistry.subscribe(id, "fake_pid_1", pid)
      state = :sys.get_state(listener_pid)

      assert state == %{id: id, subscribers: ["fake_pid_1"], registry: pid}

      :ok = BlockchainRegistry.subscribe(id, "fake_pid_2", pid)
      state = :sys.get_state(listener_pid)
      assert state == %{id: id, subscribers: ["fake_pid_2", "fake_pid_1"], registry: pid}

      :ok = BlockchainRegistry.unsubscribe(id, "fake_pid_1", pid)
      state = :sys.get_state(listener_pid)
      assert state == %{id: id, subscribers: ["fake_pid_2"], registry: pid}

      # Unsubscribing the last subscriber will stop the process
      :ok = BlockchainRegistry.unsubscribe(id, "fake_pid_2", pid)

      ref = Process.monitor(listener_pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          refute Process.alive?(listener_pid)
      after
        1_000 ->
          refute Process.alive?(listener_pid)
      end

      assert GenServer.stop(pid) == :ok
    end
  end
end
