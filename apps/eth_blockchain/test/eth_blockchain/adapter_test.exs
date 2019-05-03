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
  alias EthBlockchain.{Adapter, DumbAdapter}
  alias Ecto.UUID

  setup do
    mock_balance = 123

    Code.eval_string("""
      defmodule MockAdapter do
        def start_link, do: GenServer.start_link(__MODULE__, :ok, [])
        def init(:ok), do: {:ok, nil}
        def stop(pid), do: GenServer.stop(pid)

        def handle_call({:get_balances, _address, contract_addresses, _block}, _from, reg) do
          balances = Map.new(contract_addresses, fn ca -> {ca, #{mock_balance}} end)
          {:reply, {:ok, balances}, reg}
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
      mock_balance: mock_balance,
      mock_adapter: MockAdapter,
      supervisor: supervisor
    }
  end

  describe "call/3" do
    test "delegates call to the adapter", state do
      mock_resp =
        Adapter.call(
          :mock,
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      dumb_resp1 =
        Adapter.call(
          :dumb,
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      dumb_resp2 =
        Adapter.call(
          {:dumb, "balance"},
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      assert {:ok,
              %{
                "0x01" => state[:mock_balance],
                "0x02" => state[:mock_balance],
                "0x03" => state[:mock_balance]
              }} == mock_resp

      assert {:ok, %{"0x01" => 123, "0x02" => 123, "0x03" => 123}} == dumb_resp1
      assert {:ok, %{"0x01" => 123, "0x02" => 123, "0x03" => 123}} == dumb_resp2
    end

    test "shutdowns the worker once finished handling tasks", state do
      {:ok, _} =
        Adapter.call(
          :mock,
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      {:ok, _} =
        Adapter.call(
          :dumb,
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      {:ok, _} =
        Adapter.call(
          {:dumb, "balance"},
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      {:ok, _} =
        Adapter.call(
          {:mock, "balance"},
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      {:ok, _} =
        Adapter.call(
          :dumb,
          {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
          state[:pid]
        )

      childrens = DynamicSupervisor.which_children(state[:supervisor])
      assert childrens == []
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Adapter.call(
                 :foobar,
                 {:get_balances, "0x123", ["0x01", "0x02", "0x03"], "latest"},
                 state[:pid]
               )
    end
  end
end
