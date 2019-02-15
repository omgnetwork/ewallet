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

defmodule Blockchain.WalletTest do
  use ExUnit.Case
  alias Blockchain.{Backend, Wallet}
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
    {:ok, pid} =
      Backend.start_link(
        backends: [
          {:dumb, DumbBackend}
        ]
      )

    %{pid: pid}
  end

  describe "generate_wallet/1" do
    test "generates a wallet with the given backend spec", state do
      assert {:ok, "wallet_id", "public_key"} == Wallet.generate_wallet(:dumb)
      assert {:ok, "wallet_id", "public_key"} == Wallet.generate_wallet({:dumb, "foo"})
    end

    test "returns an error if no such backend is registered", state do
      assert {:error, :no_handler} == Wallet.generate_wallet(:blah)
    end
  end
end
