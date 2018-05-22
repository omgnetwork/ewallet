defmodule EWalletDB.CategoryTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Category

  describe "Category factory" do
    test_has_valid_factory(Category)
  end

  describe "all/1" do
    test_schema_all_returns_all_records(Category, 10)
  end

  describe "get/2" do
    test_schema_get_returns_struct_if_given_valid_id(Category)
    test_schema_get_returns_nil_for_id(Category, "cat_00000000000000000000000000")
    test_schema_get_returns_nil_for_id(Category, "not_an_id")
    test_schema_get_accepts_preload(Category, :accounts)
  end

  describe "get_by/2" do
    test_schema_get_by_allows_search_by(Category, :name)
  end

  describe "insert/1" do
    test_insert_ok(Category, :name, "Test category name")
    test_insert_generate_uuid(Category, :uuid)
    test_insert_generate_external_id(Category, :id, "cat_")
    test_insert_generate_timestamps(Category)

    test_insert_prevent_duplicate(Category, :name)
  end

  describe "update/1" do
    test_update_field_ok(Category, :name)
    test_update_field_ok(Category, :description)
  end

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at(Category)
  end

  describe "delete/1" do
    test_delete_causes_record_deleted(Category)
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted(Category)
  end
end
