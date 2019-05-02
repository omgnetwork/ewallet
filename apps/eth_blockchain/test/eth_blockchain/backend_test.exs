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
  use ExUnit.Case
  alias EthBlockchain.Adapter
  alias Ecto.UUID

  defmodule DumbAdapter do
    def start_link, do: GenServer.start_link(__MODULE__, :ok, [])
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
      defmodule MockAdapter do
        def start_link, do: GenServer.start_link(__MODULE__, :ok, [])
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
      Adapter.start_link(
        supervisor: supervisor,
        adapters: [
          {:mock, MockAdapter},
          {:dumb, DumbAdapter}
        ]
      )

    on_exit(fn ->
      :code.purge(MockAdapter)
      :code.delete(MockAdapter)
    end)

    %{
      pid: pid,
      mock_id: mock_id,
      mock_key: mock_key,
      mock_adapter: MockAdapter,
      supervisor: supervisor
    }
  end

  describe "call/3" do
    test "delegates call to the adapter", state do
      mock_resp = Adapter.call(:mock, :generate_wallet, state[:pid])
      dumb_resp1 = Adapter.call(:dumb, :generate_wallet, state[:pid])
      dumb_resp2 = Adapter.call({:dumb, "wallet"}, :generate_wallet, state[:pid])

      assert {:ok, state[:mock_id], state[:mock_key]} == mock_resp
      assert {:ok, "wallet_id", "public_key"} == dumb_resp1
      assert {:ok, "wallet_id", "public_key"} == dumb_resp2
    end

    test "shutdowns the worker once finished handling tasks", state do
      {:ok, _, _} = Adapter.call(:mock, :generate_wallet, state[:pid])
      {:ok, _, _} = Adapter.call(:dumb, :generate_wallet, state[:pid])
      {:ok, _, _} = Adapter.call({:dumb, "wallet"}, :generate_wallet, state[:pid])
      {:ok, _, _} = Adapter.call({:mock, "wallet"}, :generate_wallet, state[:pid])
      {:ok, _, _} = Adapter.call(:dumb, :generate_wallet, state[:pid])

      childrens = DynamicSupervisor.which_children(state[:supervisor])
      assert childrens == []
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} == Adapter.call(:foobar, :generate_wallet, state[:pid])
    end
  end
end
