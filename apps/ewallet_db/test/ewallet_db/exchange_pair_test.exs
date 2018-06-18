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
end
