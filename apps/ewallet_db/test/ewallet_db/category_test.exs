defmodule EWalletDB.CategoryTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Category

  describe "Category factory" do
    test_has_valid_factory(Category)
  end

  describe "all/1" do
    test "returns all existing categories" do
      assert Enum.empty?(Category.all())
      insert_list(3, :category)
      assert length(Category.all()) == 3
    end
  end

  describe "get/1" do
    test "accepts an id" do
      category = insert(:category)
      result = Category.get(category.id)

      assert result.id == category.id
    end

    test "returns nil if the given id is in an invalid format" do
      assert Category.get("not_an_id") == nil
    end

    test "returns nil if the category with the given id is not found" do
      assert Category.get("cat_00000000000000000000000000") == nil
    end
  end

  describe "get/2" do
    test "accepts an id and preload" do
      category = insert(:category)
      result = Category.get(category.id, preload: :accounts)

      assert result.id == category.id
      assert Ecto.assoc_loaded?(result.accounts)
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(Category, :uuid)
    test_insert_generate_external_id(Category, :id, "cat_")
    test_insert_generate_timestamps(Category)

    test_insert_prevent_duplicate(Category, :name)

    test "inserts and returns a Category struct" do
      {res, category} =
        :category
        |> params_for(%{name: "Test category name"})
        |> Category.insert()

      assert res == :ok
      assert category.name == "Test category name"
    end
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
