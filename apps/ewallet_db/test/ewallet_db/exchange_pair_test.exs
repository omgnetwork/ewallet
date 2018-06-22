defmodule EWalletDB.ExchangePairTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.ExchangePair

  describe "ExchangePair factory" do
    test_has_valid_factory(ExchangePair)
  end

  describe "insert/1" do
    test_insert_generate_uuid(ExchangePair, :uuid)
    test_insert_generate_external_id(ExchangePair, :id, "exg_")
    test_insert_prevent_blank(ExchangePair, :name)
    test_insert_prevent_blank(ExchangePair, :rate)
    test_insert_generate_timestamps(ExchangePair)
  end

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at(ExchangePair)
  end

  describe "delete/1" do
    test_delete_causes_record_deleted(ExchangePair)
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted(ExchangePair)
  end

  describe "fetch_exchangable_pair/3" do
    test "returns {:ok, pair, :direct} if the tokens match a direct pair" do
      omg = insert(:token)
      eth = insert(:token)
      inserted_pair = insert(:exchange_pair, from_token: omg, to_token: eth, reversible: false)

      {res, pair, direction} = ExchangePair.fetch_exchangable_pair(omg, eth)

      assert res == :ok
      assert pair.uuid == inserted_pair.uuid
      assert direction == :direct
    end

    test "returns {:ok, pair, :reversed} if the tokens match a reversed pair" do
      omg = insert(:token)
      eth = insert(:token)
      inserted_pair = insert(:exchange_pair, from_token: omg, to_token: eth, reversible: true)

      {res, pair, direction} = ExchangePair.fetch_exchangable_pair(eth, omg)

      assert res == :ok
      assert pair.uuid == inserted_pair.uuid
      assert direction == :reversed
    end

    test "returns {:error, :exchange_pair_not_found} if a pair could not be found" do
      omg = insert(:token)
      eth = insert(:token)

      {res, code} = ExchangePair.fetch_exchangable_pair(omg, eth)

      assert res == :error
      assert code == :exchange_pair_not_found
    end

    test "returns {:error, :exchange_pair_not_found} if a reversed pair is found
          but is not reversible" do
      omg = insert(:token)
      eth = insert(:token)
      _ = insert(:exchange_pair, from_token: omg, to_token: eth, reversible: false)

      {:ok, _, _} = ExchangePair.fetch_exchangable_pair(omg, eth)
      {res, code} = ExchangePair.fetch_exchangable_pair(eth, omg)

      assert res == :error
      assert code == :exchange_pair_not_found
    end
  end
end
