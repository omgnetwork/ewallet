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
          "name" => "Test pair",
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id
        })

      assert res == :ok
      assert is_list(pairs)
      assert Enum.count(pairs) == 1

      assert Enum.at(pairs, 0).name == "Test pair"
      assert Enum.at(pairs, 0).from_token_uuid == eth.uuid
      assert Enum.at(pairs, 0).to_token_uuid == omg.uuid
      assert Enum.at(pairs, 0).rate == 2.0
    end

    test "inserts an exchange pair and its opposite when sync_opposite: true" do
      eth = insert(:token)
      omg = insert(:token)

      {res, pairs} =
        ExchangePairGate.insert(%{
          "name" => "Test pair",
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "sync_opposite" => true
        })

      assert res == :ok
      assert is_list(pairs)
      assert Enum.count(pairs) == 2

      # Asserts the direct pair
      assert Enum.at(pairs, 0).name == "Test pair"
      assert Enum.at(pairs, 0).rate == 2.0

      # Asserts the opposite pair
      assert Enum.at(pairs, 1).name == "Test pair (opposite pair)"
      assert Enum.at(pairs, 1).rate == 1 / 2.0
    end

    test "rollbacks if an error occurred along the way" do
      eth = insert(:token)
      omg = insert(:token)

      # Create an opposite pair in advance so the insert will fail when creating the opposite pair
      {:ok, _} =
        ExchangePairGate.insert(%{
          "name" => "Opposite pair",
          "rate" => 0.5,
          "from_token_id" => omg.id,
          "to_token_id" => eth.id,
          "sync_opposite" => false
        })

      # This insert should fail and roll back due to conflict with successful insert above
      {res, code} =
        ExchangePairGate.insert(%{
          "name" => "This pair should rollback",
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "sync_opposite" => true
        })

      assert res == :error
      assert code == :exchange_pair_already_exists
      assert Repo.get_by(ExchangePair, name: "This pair should rollback") == nil
    end
  end

  describe "update/2" do
    test "updates an exchange pair" do
      pair = insert(:exchange_pair)

      {res, pairs} =
        ExchangePairGate.update(pair.id, %{
          "name" => "Test pair updated",
          "rate" => 999
        })

      assert res == :ok
      assert Enum.count(pairs) == 1
      assert Enum.at(pairs, 0).name == "Test pair updated"
      assert Enum.at(pairs, 0).rate == 999
    end

    test "updates an exchange pair and its opposite when sync_opposite: true" do
      pair = insert(:exchange_pair)

      _opposite_pair =
        insert(:exchange_pair, from_token: pair.to_token, to_token: pair.from_token)

      {res, pairs} =
        ExchangePairGate.update(pair.id, %{
          "name" => "Test pair updated",
          "rate" => 999,
          "sync_opposite" => true
        })

      assert res == :ok
      assert Enum.count(pairs) == 2
      assert Enum.any?(pairs, fn p -> p.rate == 999 end)
      assert Enum.any?(pairs, fn p -> p.rate == 1 / 999 end)
    end

    test "touches the opposite pair even if the value didn't change when sync_opposite: true" do
      pair = insert(:exchange_pair)
      opposite = insert(:exchange_pair, from_token: pair.to_token, to_token: pair.from_token, rate: 1 / 1_000)

      {res, pairs} =
        ExchangePairGate.update(pair.id, %{
          "rate" => 1_000,
          "sync_opposite" => true
        })

      assert res == :ok
      assert Enum.count(pairs) == 2
      assert Enum.any?(pairs, fn p -> p.id == pair.id && p.rate == 1_000 end)
      assert Enum.any?(pairs, fn p -> p.id == opposite.id && p.rate == 1 / 1_000 end)
    end

    test "rollbacks if an error occurred along the way" do
      eth = insert(:token)
      omg = insert(:token)

      # Create a pair without the opposite so an update with `sync_opposite: true` should fail
      {:ok, [pair]} =
        ExchangePairGate.insert(%{
          "name" => "Test pair",
          "rate" => 0.5,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "sync_opposite" => false
        })

      {res, code} =
        ExchangePairGate.update(pair.id, %{
          "name" => "This pair should rollback",
          "rate" => 2.0,
          "sync_opposite" => true
        })

      assert res == :error
      assert code == :exchange_opposite_pair_not_found

      # Asserts that the updates have been rolled back on the original pair
      pair = Repo.get(ExchangePair, pair.uuid)
      assert pair.name == "Test pair"
      assert pair.rate == 0.5
    end

    test "returns :exchange_pair_id_not_found error if the exchange pair is not found" do
      {res, code} =
        ExchangePairGate.update("wrong_id", %{
          "name" => "Test pair updated"
        })

      assert res == :error
      assert code == :exchange_pair_id_not_found
    end
  end

  describe "delete/1" do
    test "deletes the exchange pair"
    test "updates the exchange pair and its opposite when sync_opposite: true"
    test "rollbacks if an error occured along the way"
    test "returns :exchange_pair_id_not_found error if the exchange pair is not found"
  end
end
