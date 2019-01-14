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

defmodule LocalLedger.WalletTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedger.Wallet
  alias LocalLedgerDB.Repo

  setup do
    :ok = Sandbox.checkout(Repo)

    token_1 = insert(:token, id: "tok_OMG_1234")
    token_2 = insert(:token, id: "tok_BTC_5678")
    wallet = insert(:wallet)

    # Total: +120_000 OMG
    insert_list(
      12,
      :credit,
      token: token_1,
      wallet: wallet,
      amount: 10_000
    )

    # Total: -61_047 OMG
    insert_list(
      9,
      :debit,
      token: token_1,
      wallet: wallet,
      amount: 6_783
    )

    # Total: +160_524 BTC
    insert_list(
      12,
      :credit,
      token: token_2,
      wallet: wallet,
      amount: 13_377
    )

    # Total: -74_961 BTC
    insert_list(
      9,
      :debit,
      token: token_2,
      wallet: wallet,
      amount: 8_329
    )

    %{token_1: token_1, token_2: token_2, wallet: wallet}
  end

  describe "all_balances/1" do
    test "retrieves all balances with a list of addresses", meta do
      wallet_2 = insert(:wallet)
      {:ok, addresses_with_amounts} = Wallet.all_balances([meta.wallet.address, wallet_2.address])

      assert addresses_with_amounts == %{
               meta.wallet.address => %{
                 "tok_BTC_5678" => 160_524 - 74_961,
                 "tok_OMG_1234" => 120_000 - 61_047
               },
               wallet_2.address => %{}
             }
    end

    test "retrieves all balances with one address", meta do
      {:ok, address_with_amounts} = Wallet.all_balances(meta.wallet.address)

      assert address_with_amounts == %{
               meta.wallet.address => %{
                 "tok_BTC_5678" => 160_524 - 74_961,
                 "tok_OMG_1234" => 120_000 - 61_047
               }
             }
    end
  end

  describe "get_balance/2" do
    test "get a balance with a token id and a list of addresses", meta do
      wallet_2 = insert(:wallet)

      {:ok, addresses_with_amounts} =
        Wallet.get_balance(
          meta.token_1.id,
          [meta.wallet.address, wallet_2.address]
        )

      assert addresses_with_amounts == %{
               meta.wallet.address => %{
                 meta.token_1.id => 120_000 - 61_047
               },
               wallet_2.address => %{
                 meta.token_1.id => 0
               }
             }
    end

    test "get a balance with a token id and one address", meta do
      {:ok, addresses_with_amounts} =
        Wallet.get_balance(
          meta.token_1.id,
          meta.wallet.address
        )

      assert addresses_with_amounts == %{
               meta.wallet.address => %{
                 meta.token_1.id => 120_000 - 61_047
               }
             }
    end
  end
end
