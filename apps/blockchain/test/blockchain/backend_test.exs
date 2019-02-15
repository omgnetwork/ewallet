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

defmodule Blockchain.BackendTest do
  use ExUnit.Case
  alias Blockchain.Backend
  alias Ecto.UUID

  defmodule DumbBackend do
    def start_link(), do: GenServer.start_link(__MODULE__, :ok, [])
    def init(:ok), do: {:ok, nil}
    def stop(pid), do: GenServer.stop(pid)

    def handle_call(:generate_wallet, _from, reg) do
      {:reply, {:ok, "wallet_id", "public_key"}, reg}
    end
  end

  setup do
    mock_id = UUID.generate()
    mock_key = UUID.generate()

    Code.eval_string("""
      defmodule MockBackend do
        def start_link(), do: GenServer.start_link(__MODULE__, :ok, [])
        def init(:ok), do: {:ok, nil}
        def stop(pid), do: GenServer.stop(pid)

        def handle_call(:generate_wallet, _from, reg) do
          {:reply, {:ok, #{Macro.to_string(mock_id)}, #{Macro.to_string(mock_key)}}, reg}
        end
      end
    """)

    supervisor = String.to_atom("#{UUID.generate()}")

    {:ok, _} =
      DynamicSupervisor.start_link(
        name: supervisor,
        strategy: :one_for_one
      )

    {:ok, pid} =
      Backend.start_link(
        supervisor: supervisor,
        backends: [
          {:mock, MockBackend},
          {:dumb, DumbBackend}
        ]
      )

    on_exit(fn ->
      :code.purge(MockBackend)
      :code.delete(MockBackend)
    end)

    %{pid: pid, mock_id: mock_id, mock_key: mock_key, mock_backend: MockBackend}
  end

  describe "start_backend/1" do
    test "starts the backend", state do
      assert :ok == Backend.start_backend(:mock, state[:pid])
      assert :ok == Backend.start_backend(:dumb, state[:pid])
      assert :ok == Backend.start_backend({:mock, "foobar"}, state[:pid])
      assert :ok == Backend.start_backend({:dumb, "wallet"}, state[:pid])
    end

    test "do not start backend if one is already running", state do
      :ok = Backend.start_backend(:mock, state[:pid])
      :ok = Backend.start_backend(:mock, state[:pid])
      :ok = Backend.start_backend({:mock, "foobar"}, state[:pid])
      :ok = Backend.start_backend({:mock, "wallet"}, state[:pid])
      :ok = Backend.start_backend({:mock, "wallet"}, state[:pid])
      :ok = Backend.start_backend(:dumb, state[:pid])
      :ok = Backend.start_backend(:mock, state[:pid])
      :ok = Backend.start_backend(:dumb, state[:pid])

      {_, _, registry} = :sys.get_state(state[:pid])

      assert map_size(registry) == 4
      assert Map.has_key?(registry, {:mock, nil})
      assert Map.has_key?(registry, {:mock, "foobar"})
      assert Map.has_key?(registry, {:mock, "wallet"})
      assert Map.has_key?(registry, {:dumb, nil})
    end

    test "returns an error if no such backend is registered", state do
      assert {:error, :no_handler} == Backend.start_backend(:foo, state[:pid])
    end
  end

  describe "call/3" do
    test "delegates call to the backend", state do
      mock_resp = Backend.call(:mock, :generate_wallet, state[:pid])
      dumb_resp1 = Backend.call(:dumb, :generate_wallet, state[:pid])
      dumb_resp2 = Backend.call({:dumb, "wallet"}, :generate_wallet, state[:pid])

      assert {:ok, state[:mock_id], state[:mock_key]} == mock_resp
      assert {:ok, "wallet_id", "public_key"} == dumb_resp1
      assert {:ok, "wallet_id", "public_key"} == dumb_resp2
    end

    test "do not start backend if one is already running", state do
      {:ok, _, _} = Backend.call(:mock, :generate_wallet, state[:pid])
      {:ok, _, _} = Backend.call(:dumb, :generate_wallet, state[:pid])
      {:ok, _, _} = Backend.call({:dumb, "wallet"}, :generate_wallet, state[:pid])
      {:ok, _, _} = Backend.call({:mock, "wallet"}, :generate_wallet, state[:pid])
      {:ok, _, _} = Backend.call(:dumb, :generate_wallet, state[:pid])

      {_, _, registry} = :sys.get_state(state[:pid])

      assert map_size(registry) == 4
      assert Map.has_key?(registry, {:mock, nil})
      assert Map.has_key?(registry, {:dumb, nil})
      assert Map.has_key?(registry, {:dumb, "wallet"})
      assert Map.has_key?(registry, {:mock, "wallet"})
    end

    test "returns an error if no such backend is registered", state do
      assert {:error, :no_handler} == Backend.call(:foobar, :generate_wallet, state[:pid])
    end
  end
end
