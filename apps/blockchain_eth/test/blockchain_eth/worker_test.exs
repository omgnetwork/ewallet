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

defmodule BlockchainEth.WorkerTest do
  use ExUnit.Case
  alias BlockchainEth.Worker
  alias Ecto.Adapters.SQL.Sandbox
  alias Keychain.{Repo, Key}

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    {:ok, pid} = Worker.start_link()
    %{pid: pid}
  end

  describe "generate_wallet/0" do
    test "generates a ECDH keypair and wallet id", state do
      assert Repo.aggregate(Key, :count, :wallet_id) == 0
      {:ok, wallet_id, public_key} = Worker.generate_wallet(state[:pid])
      {:ok, _, _} = Worker.generate_wallet(state[:pid])
      {:ok, _, _} = Worker.generate_wallet(state[:pid])
      {:ok, _, _} = Worker.generate_wallet(state[:pid])
      assert Repo.aggregate(Key, :count, :wallet_id) == 4

      assert is_binary(wallet_id)
      assert byte_size(wallet_id) == 66

      assert is_binary(public_key)
      assert byte_size(public_key) == 130
    end
  end
end
