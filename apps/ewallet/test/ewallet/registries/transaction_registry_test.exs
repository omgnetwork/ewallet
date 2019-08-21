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

defmodule EWallet.TransactionRegistryTest do
  use EWallet.DBCase, async: false
  alias EWallet.{TransactionRegistry, DumbTracker}
  alias Ecto.UUID

  describe "start_link/1" do
    test "starts a new server" do
      assert {:ok, pid} = TransactionRegistry.start_link(name: :test_registry)
      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits with empty map" do
      assert TransactionRegistry.init(:ok) == {:ok, %{}}
    end
  end

  describe "lookup/1" do
    test "registers and return a registered tracker" do
      uuid = UUID.generate()
      assert {:ok, pid} = TransactionRegistry.start_link(name: :test_registry)

      :ok =
        TransactionRegistry.start_tracker(
          DumbTracker,
          %{transaction: %{uuid: uuid}, transaction_type: :from_blockchain_to_ewallet},
          pid
        )

      assert {:ok, %{tracker: DumbTracker, pid: tracker_pid}} =
               TransactionRegistry.lookup(uuid, pid)

      assert is_pid(tracker_pid)

      assert GenServer.stop(tracker_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "start_tracker/1" do
    test "returns :ok when re-registering but skip adding new tracker" do
      uuid = UUID.generate()
      assert {:ok, pid} = TransactionRegistry.start_link(name: :test_registry)

      :ok =
        TransactionRegistry.start_tracker(
          DumbTracker,
          %{transaction: %{uuid: uuid}, transaction_type: :from_blockchain_to_ewallet},
          pid
        )

      :ok =
        TransactionRegistry.start_tracker(
          DumbTracker,
          %{transaction: %{uuid: uuid}, transaction_type: :from_blockchain_to_ewallet},
          pid
        )

      assert {:ok, %{tracker: DumbTracker, pid: tracker_pid}} =
               TransactionRegistry.lookup(uuid, pid)

      assert is_pid(tracker_pid)

      registry = TransactionRegistry.get_registry(pid)

      assert %{
               ^uuid => %{
                 pid: ^tracker_pid,
                 tracker: DumbTracker
               }
             } = registry

      assert GenServer.stop(tracker_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end
  end
end
