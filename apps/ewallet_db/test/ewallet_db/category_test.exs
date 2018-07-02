defmodule EWalletDB.CategoryTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Category

  defp insert_category(accounts) do
    account_ids = Enum.map(accounts, fn account -> account.id end)

    :category
    |> params_for()
    |> Map.put(:account_ids, account_ids)
    |> Category.insert()
  end

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

  describe "update/2 with account_ids" do
    test "associates the account if it's been added to account_ids" do
      # Prepare 4 accounts. We will start off the category with 2, add 1, and leave one behind.
      [acc1, acc2, acc3, _not_used] = insert_list(4, :account)
      {:ok, category} = insert_category([acc1, acc2])

      # Make sure that the category has 2 accounts
      assert_accounts(category, [acc1, acc2])

      # Now update with additional account_ids
      {:ok, updated} = Category.update(category, %{account_ids: [acc1.id, acc2.id, acc3.id]})

      # Assert that the 3rd account is added
      assert_accounts(updated, [acc1, acc2, acc3])
    end

    test "removes the account if it's no longer in the account_ids" do
      [acc1, acc2] = insert_list(2, :account)
      {:ok, category} = insert_category([acc1, acc2])

      # Make sure that the category has 2 accounts
      assert_accounts(category, [acc1, acc2])

      # Now update by removing a account from category_ids
      {:ok, updated} = Category.update(category, %{account_ids: [acc1.id]})

      # Only one account should be left
      assert_accounts(updated, [acc1])
    end

    test "removes all accounts if account_ids is an empty list" do
      [acc1, acc2] = insert_list(2, :account)
      {:ok, category} = insert_category([acc1, acc2])

      # Make sure that the category has 2 accounts
      assert_accounts(category, [acc1, acc2])

      # Now update by setting account_ids to an empty list
      {:ok, updated} = Category.update(category, %{account_ids: []})

      # No category should be left
      assert_accounts(updated, [])
    end

    test "does nothing if account_ids is nil" do
      [acc1, acc2] = insert_list(2, :account)
      {:ok, category} = insert_category([acc1, acc2])

      # Make sure that the category has 2 accounts
      assert_accounts(category, [acc1, acc2])

      # Now update by passing a nil account_ids
      {:ok, updated} = Category.update(category, %{account_ids: nil})

      # The categories should remain the same
      assert_accounts(updated, [acc1, acc2])
    end

    defp assert_accounts(category, expected) do
      actual_account_ids =
        category
        |> Repo.preload(:accounts)
        |> Map.get(:accounts)
        |> Enum.map(fn account -> account.id end)

      assert Enum.all?(expected, fn account ->
               account.id in actual_account_ids
             end)

      assert Enum.count(actual_account_ids) == Enum.count(expected)
    end
  end

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at(Category)
  end

  describe "delete/1" do
    test_delete_causes_record_deleted(Category)

    test "returns :category_not_empty error if the category has associated accounts" do
      account = insert(:account)
      {:ok, category} = insert_category([account])

      # Make sure that the category has an account
      assert_accounts(category, [account])

      {res, code} = Category.delete(category)

      assert res == :error
      assert code == :category_not_empty
      refute category.id |> Category.get() |> Category.deleted?()
    end
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted(Category)
  end
end
