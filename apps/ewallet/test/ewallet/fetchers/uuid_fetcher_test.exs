defmodule EWallet.UUIDFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.UUIDFetcher
  alias EWalletDB.{Account, User}

  describe "replace_external_ids/1" do
    test "turns multiple external IDs into internal UUIDs" do
      user = insert(:user)
      account = insert(:account)

      attrs = %{
        "user_id" => user.id,
        "account_id" => account.id
      }

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res["account_uuid"] == account.uuid
      assert %Account{} = res["account"]
      assert res["user_uuid"] == user.uuid
      assert %User{} = res["user"]
    end

    test "turns external IDs into internal UUIDs" do
      account = insert(:account)
      attrs = %{"account_id" => account.id}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res["account_uuid"] == account.uuid
      assert %Account{} = res["account"]
    end

    test "turns external IDs into internal UUIDs if the record does not exist" do
      attrs = %{"account_id" => "some_id"}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res["account_uuid"] == nil
      assert res["account"] == nil
    end

    test "returns the same attributes if no external IDs is given" do
      attrs = %{"something" => "else"}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res == %{"something" => "else"}
    end

    test "returns the same attributes if external IDs are not supported" do
      attrs = %{"something_id" => "fake_id"}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res == %{"something_id" => "fake_id"}
    end
  end
end
