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

    test "prevents from_token_uuid and to_token_uuid having the same value" do
      omg = insert(:token)

      attrs = %{
        name: "Test pair",
        from_token_uuid: omg.uuid,
        to_token_uuid: omg.uuid,
        rate: 1.00
      }

      {res, changeset} = ExchangePair.insert(attrs)

      assert res == :error

      assert changeset.errors == [
               {:to_token_uuid,
                {"can't have the same value as `from_token_uuid`",
                 [validation: :different_values]}}
             ]
    end
  end

  describe "update/2" do
    test_update_field_ok(ExchangePair, :name)
    test_update_field_ok(ExchangePair, :rate, 2.00, 9.99)

    test_update_prevents_changing(
      ExchangePair,
      :from_token_uuid,
      insert(:token).uuid,
      insert(:token).uuid
    )

    test_update_prevents_changing(
      ExchangePair,
      :to_token_uuid,
      insert(:token).uuid,
      insert(:token).uuid
    )
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
      inserted_pair = insert(:exchange_pair, from_token: omg, to_token: eth)

      {res, pair, direction} = ExchangePair.fetch_exchangable_pair(omg, eth)

      assert res == :ok
      assert pair.uuid == inserted_pair.uuid
      assert direction == :direct
    end

    test "returns {:error, :exchange_pair_not_found} if a pair could not be found" do
      omg = insert(:token)
      eth = insert(:token)

      {res, code} = ExchangePair.fetch_exchangable_pair(omg, eth)

      assert res == :error
      assert code == :exchange_pair_not_found
    end
  end
end
