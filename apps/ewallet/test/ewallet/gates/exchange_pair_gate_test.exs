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

defmodule EWallet.ExchangePairGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.ExchangePairGate
  alias EWalletDB.{ExchangePair, Repo}
  alias ActivityLogger.System

  describe "insert/2" do
    test "inserts an exchange pair" do
      eth = insert(:token)
      omg = insert(:token)

      {res, pairs} =
        ExchangePairGate.insert(%{
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "originator" => %System{}
        })

      assert res == :ok
      assert is_list(pairs)
      assert Enum.count(pairs) == 1

      assert Enum.at(pairs, 0).from_token_uuid == eth.uuid
      assert Enum.at(pairs, 0).to_token_uuid == omg.uuid
      assert Enum.at(pairs, 0).rate == 2.0
    end

    test "inserts an exchange pair and its opposite when sync_opposite: true" do
      eth = insert(:token)
      omg = insert(:token)

      {res, pairs} =
        ExchangePairGate.insert(%{
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "sync_opposite" => true,
          "originator" => %System{}
        })

      assert res == :ok
      assert is_list(pairs)
      assert Enum.count(pairs) == 2

      # Asserts the direct pair
      assert Enum.at(pairs, 0).from_token_uuid == eth.uuid
      assert Enum.at(pairs, 0).to_token_uuid == omg.uuid
      assert Enum.at(pairs, 0).rate == 2.0

      # Asserts the opposite pair
      assert Enum.at(pairs, 1).from_token_uuid == omg.uuid
      assert Enum.at(pairs, 1).to_token_uuid == eth.uuid
      assert Enum.at(pairs, 1).rate == 1 / 2.0
    end

    test "accepts the rate as string" do
      eth = insert(:token)
      omg = insert(:token)

      {res, pairs} =
        ExchangePairGate.insert(%{
          "rate" => "3.14159",
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "sync_opposite" => true,
          "originator" => %System{}
        })

      assert res == :ok
      assert hd(pairs).rate == 3.14159
    end

    test "returns error if the string rate cannot be parsed" do
      eth = insert(:token)
      omg = insert(:token)

      {res, error, description} =
        ExchangePairGate.insert(%{
          "rate" => "not a rate",
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "sync_opposite" => true,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :invalid_parameter

      assert description ==
               "Invalid parameter provided. `rate` cannot be parsed. Got: \"not a rate\""
    end

    test "rollbacks if an error occurred along the way" do
      eth = insert(:token)
      omg = insert(:token)

      # Create an opposite pair in advance so the insert will fail when creating the opposite pair
      _ = insert(:exchange_pair, from_token: omg, to_token: eth)

      # This insert should fail and roll back due to conflict with successful insert above
      {res, code} =
        ExchangePairGate.insert(%{
          "rate" => 927_361,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "sync_opposite" => true,
          "originator" => %System{}
        })

      assert res == :error
      assert code == :exchange_pair_already_exists
      assert Repo.get_by(ExchangePair, rate: 927_361) == nil
    end
  end

  describe "update/2" do
    test "updates an exchange pair" do
      pair = insert(:exchange_pair)

      {res, pairs} =
        ExchangePairGate.update(pair.id, %{
          "rate" => 999,
          "originator" => %System{}
        })

      assert res == :ok
      assert Enum.count(pairs) == 1
      assert Enum.at(pairs, 0).id == pair.id
      assert Enum.at(pairs, 0).rate == 999
    end

    test "updates an exchange pair and its opposite when sync_opposite: true" do
      pair = insert(:exchange_pair)
      opposite = insert(:exchange_pair, from_token: pair.to_token, to_token: pair.from_token)

      {res, pairs} =
        ExchangePairGate.update(pair.id, %{
          "rate" => 777,
          "sync_opposite" => true,
          "originator" => %System{}
        })

      assert res == :ok
      assert Enum.count(pairs) == 2
      assert Enum.any?(pairs, fn p -> p.id == pair.id && p.rate == 777 end)
      assert Enum.any?(pairs, fn p -> p.id == opposite.id && p.rate == 1 / 777 end)
    end

    test "rollbacks if an error occurred along the way" do
      # Create a pair without the opposite so an update with `sync_opposite: true` should fail
      pair = insert(:exchange_pair, rate: 2329)

      {res, code} =
        ExchangePairGate.update(pair.id, %{
          "rate" => 999,
          "sync_opposite" => true,
          "originator" => %System{}
        })

      assert res == :error
      assert code == :exchange_opposite_pair_not_found

      # Asserts that the updates have been rolled back on the original pair
      pair = ExchangePair.get(pair.id)
      assert pair.rate == 2329
    end

    test "returns :exchange_pair_id_not_found error if the exchange pair is not found" do
      {res, code} =
        ExchangePairGate.update("wrong_id", %{
          "rate" => 999,
          "originator" => %System{}
        })

      assert res == :error
      assert code == :exchange_pair_id_not_found
    end
  end

  describe "delete/1" do
    test "deletes the exchange pair" do
      pair = insert(:exchange_pair)

      {res, deleted} = ExchangePairGate.delete(pair.id, %{"sync_opposite" => false}, %System{})

      assert res == :ok
      assert Enum.count(deleted) == 1
      assert Enum.at(deleted, 0).id == pair.id
      assert deleted |> Enum.at(0) |> ExchangePair.deleted?()
    end

    test "deletes the exchange pair and its opposite when sync_opposite: true" do
      pair = insert(:exchange_pair)
      opposite = insert(:exchange_pair, from_token: pair.to_token, to_token: pair.from_token)

      {res, deleted} = ExchangePairGate.delete(pair.id, %{"sync_opposite" => true}, %System{})

      assert res == :ok
      assert Enum.count(deleted) == 2
      assert Enum.any?(deleted, fn d -> d.id == pair.id && ExchangePair.deleted?(d) end)
      assert Enum.any?(deleted, fn d -> d.id == opposite.id && ExchangePair.deleted?(d) end)
    end

    test "rollbacks if an error occured along the way" do
      # Create a pair without the opposite so a deletion with `sync_opposite: true` should fail
      pair = insert(:exchange_pair, rate: 2.0)

      {res, code} = ExchangePairGate.delete(pair.id, %{"sync_opposite" => true}, %System{})

      assert res == :error
      assert code == :exchange_opposite_pair_not_found

      # Asserts that the deletion has been rolled back and the inserted pair still exists
      pair = ExchangePair.get(pair.id)
      assert pair.rate == 2.0
      refute ExchangePair.deleted?(pair)
    end

    test "returns :exchange_pair_id_not_found error if the exchange pair is not found" do
      {res, code} = ExchangePairGate.delete("wrong_id", %{}, %System{})

      assert res == :error
      assert code == :exchange_pair_id_not_found
    end
  end

  describe "add_opposite_pairs/1" do
    test "adds the opposite pairs infos to the given list of exchange pairs and keep the order" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      token_3 = insert(:token)
      token_4 = insert(:token)

      pair_1 = insert(:exchange_pair, from_token: token_1, to_token: token_2)
      pair_2 = insert(:exchange_pair, from_token: token_1, to_token: token_3)
      pair_3 = insert(:exchange_pair, from_token: token_1, to_token: token_4)
      pair_4 = insert(:exchange_pair, from_token: token_2, to_token: token_3)

      opp_pair_1 = insert(:exchange_pair, from_token: token_2, to_token: token_1)
      opp_pair_2 = insert(:exchange_pair, from_token: token_3, to_token: token_1)

      updated_pairs = ExchangePairGate.add_opposite_pairs([pair_1, pair_2, pair_3, pair_4])

      updated_pair_1 = Enum.at(updated_pairs, 0)
      updated_pair_2 = Enum.at(updated_pairs, 1)
      updated_pair_3 = Enum.at(updated_pairs, 2)
      updated_pair_4 = Enum.at(updated_pairs, 3)

      assert updated_pair_1.uuid == pair_1.uuid
      assert updated_pair_2.uuid == pair_2.uuid
      assert updated_pair_3.uuid == pair_3.uuid
      assert updated_pair_4.uuid == pair_4.uuid

      assert updated_pair_1.opposite_exchange_pair.uuid == opp_pair_1.uuid
      assert updated_pair_2.opposite_exchange_pair.uuid == opp_pair_2.uuid
      assert updated_pair_3.opposite_exchange_pair == nil
      assert updated_pair_4.opposite_exchange_pair == nil
    end
  end

  describe "add_opposite_pair/1" do
    test "adds the opposite pair infos to an exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      pair_1 = insert(:exchange_pair, from_token: token_1, to_token: token_2)

      opp_pair = insert(:exchange_pair, from_token: token_2, to_token: token_1)

      updated_pair = ExchangePairGate.add_opposite_pair(pair_1)

      assert updated_pair.opposite_exchange_pair.uuid == opp_pair.uuid
    end
  end
end
