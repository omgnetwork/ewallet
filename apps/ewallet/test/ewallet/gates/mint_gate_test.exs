# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.MintGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias Ecto.UUID
  alias EWallet.MintGate
  alias EWalletDB.Token
  alias ActivityLogger.System

  describe "insert/2" do
    test "inserts a new confirmed mint" do
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()

      {res, mint, transaction} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => btc.id,
          "amount" => 10_000 * btc.subunit_to_unit,
          "description" => "Minting 10_000 #{btc.symbol}",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == true
      assert transaction.status == "confirmed"
    end

    test "inserts a new confirmed mint with big number" do
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()

      {res, mint, transaction} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => btc.id,
          "amount" => 100_000_000_000_000_000_000_000_000_000_000_000 - 1,
          "description" => "Minting 10_000 #{btc.symbol}",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == true
      assert mint.amount == 100_000_000_000_000_000_000_000_000_000_000_000 - 1
      assert transaction.status == "confirmed"
    end

    test "fails to insert a new mint when the data is invalid" do
      {:ok, token} = Token.insert(params_for(:token))

      {res, changeset} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => token.id,
          "amount" => nil,
          "description" => "description",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :error

      assert changeset.errors == [
               amount: {"can't be blank", [validation: :required]}
             ]
    end
  end
end
