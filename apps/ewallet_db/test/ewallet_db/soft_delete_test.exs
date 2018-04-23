defmodule EWalletDB.SoftDeleteTest do
  use EWalletDB.SchemaCase
  import EWalletDB.SoftDelete
  alias EWalletDB.{Key, Repo}

  describe "exclude_deleted/1" do
    test "returns records that are not soft-deleted" do
      key = insert(:key)
      {:ok, deleted} = :key |> insert() |> Key.delete()

      result =
        Key
        |> exclude_deleted()
        |> Repo.all()

      refute Enum.any?(result, fn k -> k.id == deleted.id end)
      assert Enum.any?(result, fn k -> k.id == key.id end)
    end
  end

  describe "deleted?/1" do
    test "returns true if record is soft-deleted" do
      {:ok, key} = :key |> insert() |> Key.delete()
      assert Key.deleted?(key)
    end

    test "returns true if record is not soft-deleted" do
      key = insert(:key)
      refute Key.deleted?(key)
    end
  end

  describe "delete/2" do
    test "returns an :ok with the soft-deleted record" do
      {res, key} = :key |> insert() |> Key.delete()

      assert res == :ok
      assert Key.deleted?(key)
    end

    test "populates :deleted_at field" do
      {:ok, key} = :key |> insert() |> Key.delete()
      assert key.deleted_at != nil
    end
  end

  describe "restore/2" do
    test "returns an :ok with the record not soft-deleted" do
      {res, key} = :key |> insert() |> Key.restore()

      assert res == :ok
      refute Key.deleted?(key)
    end

    test "set :deleted_at field to nil" do
      {:ok, key} = :key |> insert() |> Key.restore()
      assert key.deleted_at == nil
    end
  end
end
