defmodule EWallet.ExchangePairGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.ExchangePairGate
  alias EWalletDB.{ExchangePair, Repo}

  describe "insert/2" do
    test "inserts an exchange pair" do
      eth = insert(:token)
      omg = insert(:token)

      {res, pairs} =
        ExchangePairGate.insert(%{
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id
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
          "sync_opposite" => true
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
          "sync_opposite" => true
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
          "rate" => 999
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
          "sync_opposite" => true
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
          "sync_opposite" => true
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
          "rate" => 999
        })

      assert res == :error
      assert code == :exchange_pair_id_not_found
    end
  end

  describe "delete/1" do
    test "deletes the exchange pair" do
      pair = insert(:exchange_pair)

      {res, deleted} = ExchangePairGate.delete(pair.id, %{"sync_opposite" => false})

      assert res == :ok
      assert Enum.count(deleted) == 1
      assert Enum.at(deleted, 0).id == pair.id
      assert deleted |> Enum.at(0) |> ExchangePair.deleted?()
    end

    test "deletes the exchange pair and its opposite when sync_opposite: true" do
      pair = insert(:exchange_pair)
      opposite = insert(:exchange_pair, from_token: pair.to_token, to_token: pair.from_token)

      {res, deleted} = ExchangePairGate.delete(pair.id, %{"sync_opposite" => true})

      assert res == :ok
      assert Enum.count(deleted) == 2
      assert Enum.any?(deleted, fn d -> d.id == pair.id && ExchangePair.deleted?(d) end)
      assert Enum.any?(deleted, fn d -> d.id == opposite.id && ExchangePair.deleted?(d) end)
    end

    test "rollbacks if an error occured along the way" do
      # Create a pair without the opposite so a deletion with `sync_opposite: true` should fail
      pair = insert(:exchange_pair, rate: 2.0)

      {res, code} = ExchangePairGate.delete(pair.id, %{"sync_opposite" => true})

      assert res == :error
      assert code == :exchange_opposite_pair_not_found

      # Asserts that the deletion has been rolled back and the inserted pair still exists
      pair = ExchangePair.get(pair.id)
      assert pair.rate == 2.0
      refute ExchangePair.deleted?(pair)
    end

    test "returns :exchange_pair_id_not_found error if the exchange pair is not found" do
      {res, code} = ExchangePairGate.delete("wrong_id", %{})

      assert res == :error
      assert code == :exchange_pair_id_not_found
    end
  end
end
