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

defmodule LocalLedgerDB.CachedBalanceTest do
  use ExUnit.Case
  import Ecto.Query
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedgerDB.{CachedBalance, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "all/1" do
    test "retrieves the latest cached balances for the given addresses" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      _cached_balance_1 = insert(:cached_balance, wallet_address: wallet_1.address)
      cached_balance_2 = insert(:cached_balance, wallet_address: wallet_1.address)
      cached_balance_3 = insert(:cached_balance, wallet_address: wallet_2.address)

      cached_balances = CachedBalance.all([wallet_1.address, wallet_2.address])
      assert length(cached_balances) == 2
      cached_balances_uuids = Enum.map(cached_balances, fn cb -> cb.uuid end)

      assert Enum.member?(cached_balances_uuids, cached_balance_2.uuid)
      assert Enum.member?(cached_balances_uuids, cached_balance_3.uuid)
    end
  end

  describe "get/1" do
    test "retrieves the latest cached balance for the given address" do
      wallet = insert(:wallet)
      _cached_balance_1 = insert(:cached_balance, wallet_address: wallet.address)
      cached_balance_2 = insert(:cached_balance, wallet_address: wallet.address)

      cached_balance = CachedBalance.get(wallet.address)
      assert cached_balance != nil
      assert cached_balance.uuid == cached_balance_2.uuid
    end
  end

  describe "insert/1" do
    test "inserts a new cached balance" do
      wallet = insert(:wallet)

      {res, cached_balance} =
        CachedBalance.insert(%{
          wallet_address: wallet.address,
          amounts: %{"token" => 100},
          cached_count: 3,
          computed_at: NaiveDateTime.utc_now()
        })

      assert res == :ok
      assert %CachedBalance{} = cached_balance
      assert cached_balance.computed_at != nil
      assert cached_balance.cached_count == 3
    end
  end

  describe "delete_since/2" do
    test "deletes all cached balances for the given address since the given computed time" do
      wallet = insert(:wallet)
      wallet_2 = insert(:wallet)
      cb_1 = insert(:cached_balance, wallet_address: wallet.address)
      cb_2 = insert(:cached_balance, wallet_address: wallet.address)
      cb_3 = insert(:cached_balance, wallet_address: wallet_2.address)
      cb_4 = insert(:cached_balance, wallet_address: wallet.address)

      # Make sure all data exists
      assert all_uuids_by_address(wallet.address) == [cb_1.uuid, cb_2.uuid, cb_4.uuid]
      assert all_uuids_by_address(wallet_2.address) == [cb_3.uuid]

      # Perform the deletion
      assert CachedBalance.delete_since(wallet.address, cb_2.computed_at) == {:ok, 2}

      # Asserts for the remaining cached balances
      assert all_uuids_by_address(wallet.address) == [cb_1.uuid]
      assert all_uuids_by_address(wallet_2.address) == [cb_3.uuid]
    end

    test "supports passing multiple addresses" do
      wallet = insert(:wallet)
      wallet_2 = insert(:wallet)
      cb_1 = insert(:cached_balance, wallet_address: wallet.address)
      cb_2 = insert(:cached_balance, wallet_address: wallet_2.address)
      cb_3 = insert(:cached_balance, wallet_address: wallet.address)
      cb_4 = insert(:cached_balance, wallet_address: wallet_2.address)

      # Make sure all data exists
      assert all_uuids_by_address(wallet.address) == [cb_1.uuid, cb_3.uuid]
      assert all_uuids_by_address(wallet_2.address) == [cb_2.uuid, cb_4.uuid]

      # Perform the deletion
      assert CachedBalance.delete_since([wallet.address, wallet_2.address], cb_3.computed_at) == {:ok, 2}

      # Asserts for the remaining cached balances
      assert all_uuids_by_address(wallet.address) == [cb_1.uuid]
      assert all_uuids_by_address(wallet_2.address) == [cb_2.uuid]
    end

    defp all_uuids_by_address(address) do
      CachedBalance
      |> where(wallet_address: ^address)
      |> select([c], c.uuid)
      |> Repo.all()
    end
  end
end
