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

defmodule EWalletDB.AccountTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.Helpers.Preloader
  alias EWalletDB.{Account, Repo}
  alias ActivityLogger.System

  describe "Account factory" do
    test_has_valid_factory(Account)
    test_encrypted_map_field(Account, "account", :encrypted_metadata)
  end

  describe "Account.insert/1" do
    test_insert_generate_uuid(Account, :uuid)
    test_insert_generate_external_id(Account, :id, "acc_")
    test_insert_generate_timestamps(Account)
    test_insert_prevent_blank(Account, :name)
    test_insert_prevent_duplicate(Account, :name)
    test_default_metadata_fields(Account, "account")

    test "inserts a non-master account by default" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      refute Account.master?(account)
    end

    test "inserts and associates categories when provided a list of category_ids" do
      [cat1, cat2] = insert_list(2, :category, originator: nil)

      {:ok, account} =
        :account
        |> params_for()
        |> Map.put(:category_ids, [cat1.id, cat2.id])
        |> Account.insert()

      account = Repo.preload(account, :categories)

      assert Enum.member?(account.categories, cat1)
      assert Enum.member?(account.categories, cat2)
      assert Enum.count(account.categories) == 2
    end

    test "inserts primary/burn wallets for the account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      primary = Account.get_primary_wallet(account)
      burn = Account.get_default_burn_wallet(account)

      assert primary != nil
      assert burn != nil
      assert length(account.wallets) == 2
    end
  end

  describe "update/2" do
    test_update_field_ok(Account, :name)
    test_update_field_ok(Account, :description)
  end

  describe "update/2 with category_ids" do
    test "associates the category if it's been added to category_ids" do
      # Prepare 4 categories. We will start off the account with 2, add 1, and leave one behind.
      [cat1, cat2, cat3, _not_used] = insert_list(4, :category, originator: nil)

      {:ok, account} =
        :account
        |> params_for()
        |> Map.put(:category_ids, [cat1.id, cat2.id])
        |> Account.insert()

      # Make sure that the account has 2 categories
      assert_categories(account, [cat1, cat2])

      # Now update with additional category_ids
      {:ok, updated} =
        Account.update(account, %{
          category_ids: [cat1.id, cat2.id, cat3.id],
          originator: %System{}
        })

      # Assert that the 3rd category is added
      assert_categories(updated, [cat1, cat2, cat3])
    end

    test "removes the category if it's no longer in the category_ids" do
      [cat1, cat2] = insert_list(2, :category, originator: nil)

      {:ok, account} =
        :account
        |> params_for()
        |> Map.put(:category_ids, [cat1.id, cat2.id])
        |> Account.insert()

      # Make sure that the account has 2 categories
      assert_categories(account, [cat1, cat2])

      # Now update by removing a category from category_ids
      {:ok, updated} =
        Account.update(account, %{
          category_ids: [cat1.id],
          originator: %System{}
        })

      # Only one category should be left
      assert_categories(updated, [cat1])
    end

    test "removes all categories if category_ids is an empty list" do
      [cat1, cat2] = insert_list(2, :category, originator: nil)

      {:ok, account} =
        :account
        |> params_for()
        |> Map.put(:category_ids, [cat1.id, cat2.id])
        |> Account.insert()

      # Make sure that the account has 2 categories
      assert_categories(account, [cat1, cat2])

      # Now update by setting category_ids to an empty list
      {:ok, updated} =
        Account.update(account, %{
          category_ids: [],
          originator: %System{}
        })

      # No category should be left
      assert_categories(updated, [])
    end

    test "does nothing if category_ids is nil" do
      [cat1, cat2] = insert_list(2, :category, originator: nil)

      {:ok, account} =
        :account
        |> params_for()
        |> Map.put(:category_ids, [cat1.id, cat2.id])
        |> Account.insert()

      # Make sure that the account has 2 categories
      assert_categories(account, [cat1, cat2])

      # Now update by passing a nil category_ids
      {:ok, updated} =
        Account.update(account, %{
          category_ids: nil,
          originator: %System{}
        })

      # The categories should remain the same
      assert_categories(updated, [cat1, cat2])
    end

    defp assert_categories(account, expected) do
      account = Repo.preload(account, :categories)

      Enum.each(expected, fn category ->
        assert Enum.member?(account.categories, category)
      end)

      assert Enum.count(account.categories) == Enum.count(expected)
    end
  end

  describe "get/2" do
    test_schema_get_returns_struct_if_given_valid_id(Account)
    test_schema_get_returns_nil_for_id(Account, "not_an_id")
    test_schema_get_returns_nil_for_id(Account, "acc_00000000000000000000000000")
    test_schema_get_accepts_preload(Account, :wallets)
  end

  describe "get_by/2" do
    test_schema_get_by_allows_search_by(Account, :name)
  end

  describe "get_master_account/0" do
    test "returns the master account" do
      result = Account.get_master_account()

      assert result.id == get_or_insert_master_account().id
      assert %Ecto.Association.NotLoaded{} = result.wallets
      assert Account.master?(result)
    end

    test "returns the master account with wallets if preload is given" do
      result = Account.get_master_account(preload: :wallets)

      assert result.id == get_or_insert_master_account().id
      assert Account.master?(result)
    end

    test "returns nil if the master account could not be found" do
      {:ok, _} = Repo.delete(Account.get_master_account())

      assert Account.get_master_account() == nil
    end
  end

  describe "fetch_master_account/0" do
    test "returns {:ok, account} on success" do
      {res, account} = Account.fetch_master_account()

      assert res == :ok
      assert Account.master?(account)
    end

    test "returns {:error, :missing_master_account} when the master account is missing" do
      {:ok, _} = Repo.delete(Account.get_master_account())
      {res, code} = Account.fetch_master_account()

      assert res == :error
      assert code == :missing_master_account
    end
  end

  describe "get_primary_wallet/1" do
    test "returns the primary wallet" do
      {:ok, inserted} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(inserted)

      [name: inserted.name]
      |> Account.get_by()
      |> Repo.preload([:wallets])

      assert wallet != nil
      assert wallet.name == "primary"
      assert wallet.identifier == "primary"
    end
  end

  describe "get_default_burn_wallet/1" do
    test "returns the burn wallet" do
      {:ok, inserted} = :account |> params_for() |> Account.insert()
      wallet = Account.get_default_burn_wallet(inserted)

      [name: inserted.name]
      |> Account.get_by()
      |> Repo.preload([:wallets])

      assert wallet != nil
      assert wallet.name == "burn"
      assert wallet.identifier == "burn"
    end
  end

  describe "add_category/2" do
    test "returns an account with the added category" do
      [cat1, cat2] = insert_list(2, :category, originator: nil)

      account =
        :account
        |> insert(categories: [cat1])
        |> Preloader.preload(:categories)

      assert account.categories == [cat1]

      {:ok, account} = Account.add_category(account, cat2, %System{})
      account = Account.get(account.id, preload: :categories)

      assert Enum.member?(account.categories, cat1)
      assert Enum.member?(account.categories, cat2)
      assert Enum.count(account.categories) == 2
    end
  end

  describe "remove_category/2" do
    test "returns an account with the removed category" do
      [cat1, cat2] = insert_list(2, :category, originator: nil)

      account =
        :account
        |> insert(categories: [cat1, cat2])
        |> Preloader.preload(:categories)

      assert Enum.member?(account.categories, cat1)
      assert Enum.member?(account.categories, cat2)
      assert Enum.count(account.categories) == 2

      {:ok, account} = Account.remove_category(account, cat1, %System{})
      account = Account.get(account.id, preload: :categories)

      assert Enum.member?(account.categories, cat2)
      assert Enum.count(account.categories) == 1
    end
  end
end
