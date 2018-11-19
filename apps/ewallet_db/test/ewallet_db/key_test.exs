defmodule EWalletDB.KeyTest do
  use EWalletDB.SchemaCase
  alias Ecto.UUID
  alias EWalletDB.Key

  describe "Key factory" do
    test_has_valid_factory(Key)
  end

  describe "all/0" do
    test "returns all tokens" do
      assert Enum.empty?(Key.all())
      insert_list(3, :key)

      assert length(Key.all()) == 3
    end

    test "returns all tokens excluding soft deleted" do
      assert Enum.empty?(Key.all())
      keys = insert_list(5, :key)
      # Soft delete d key
      {:ok, _key} = keys |> Enum.at(0) |> Key.delete()

      assert length(Key.all()) == 4
    end
  end

  describe "get/1" do
    test "accepts a uuid" do
      key = insert(:key)
      result = Key.get(key.id)
      assert result.uuid == key.uuid
    end

    test "does not return a soft-deleted key" do
      {:ok, key} = :key |> insert() |> Key.delete()
      assert Key.get(key.id) == nil
    end

    test "returns nil if the given uuid is invalid" do
      assert Key.get("not_a_uuid") == nil
    end

    test "returns nil if the key with the given uuid is not found" do
      assert Key.get(UUID.generate()) == nil
    end
  end

  describe "get/2" do
    test "returns a key if provided an access_key" do
      key = insert(:key)
      result = Key.get(:access_key, key.access_key)
      assert result.uuid == key.uuid
    end

    test "does not return a soft-deleted key" do
      {:ok, key} = :key |> insert() |> Key.delete()
      assert Key.get(:access_key, key.access_key) == nil
    end

    test "returns nil if the key with the given access_key is not found" do
      assert Key.get(:access_key, "not_access_key") == nil
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(Key, :uuid)
    test_insert_generate_external_id(Key, :id, "key_")
    test_insert_generate_timestamps(Key)
    test_insert_generate_length(Key, :access_key, 43)
    test_insert_generate_length(Key, :secret_key, 171)
    test_insert_prevent_duplicate(Key, :access_key)

    test "hashes secret_key with sha384 and hex digest it before saving" do
      {res, key} = Key.insert(params_for(:key, %{secret_key: "my_secret"}))

      hashed =
        :crypto.hash(:sha384, "my_secret")
        |> Base.encode16(padding: false)
        |> String.downcase()

      assert res == :ok
      assert hashed == key.secret_key_hash
      refute key.secret_key == key.secret_key_hash
    end

    test "does not save secret_key to database" do
      {:ok, key} = Key.insert(params_for(:key))
      assert Repo.get(Key, key.uuid).secret_key == nil
    end
  end

  describe "enable_or_disable/2" do
    test "disable a key successfuly when given 'expired' attribute" do
      {:ok, key} = Key.insert(params_for(:key))
      assert key.enabled == true

      {:ok, updated} = Key.enable_or_disable(key, %{"expired" => true})
      assert updated.enabled == false
    end

    test "disable a key successfuly when given 'enabled' attribute" do
      {:ok, key} = Key.insert(params_for(:key))
      assert key.enabled == true

      {:ok, updated} = Key.enable_or_disable(key, %{enabled: false})
      assert updated.enabled == false
    end

    test "enable a key successfuly when given 'expired' attribute" do
      {:ok, key} = Key.insert(params_for(:key, %{enabled: false}))
      assert key.enabled == false

      {:ok, updated} = Key.enable_or_disable(key, %{"expired" => false})
      assert updated.enabled == true
    end

    test "enable a key successfuly when given 'enabled' attribute" do
      {:ok, key} = Key.insert(params_for(:key, %{enabled: false}))
      assert key.enabled == false

      {:ok, updated} = Key.enable_or_disable(key, %{enabled: true})
      assert updated.enabled == true
    end
  end

  describe "authenticate/2" do
    test "returns an existing key if access and secret key match" do
      account = insert(:account)

      :key
      |> params_for(%{
        access_key: "access123",
        secret_key: "secret321",
        account: account
      })
      |> Key.insert()

      {res, key} = Key.authenticate("access123", Base.url_encode64("secret321"))
      assert res == :ok
      assert %Key{} = key
      assert key.account.uuid == account.uuid
    end

    test "returns false if access key is disabled" do
      account = insert(:account)

      {:ok, key} =
        :key
        |> params_for(%{
          access_key: "access123",
          secret_key: "secret321",
          account: account
        })
        |> Key.insert()

      {:ok, _key} =
        Key.enable_or_disable(key, %{
          enabled: false
        })

      res = Key.authenticate("access123", Base.url_encode64("secret321"))
      assert res == false
    end

    test "returns false if access_key and/or secret_key do not match" do
      :key
      |> params_for(%{access_key: "access123", secret_key: "secret321"})
      |> Key.insert()

      assert Key.authenticate("access123", Base.url_encode64("unmatched")) == false
      assert Key.authenticate("unmatched", Base.url_encode64("secret321")) == false
      assert Key.authenticate("unmatched", Base.url_encode64("unmatched")) == false
    end

    test "returns false if access_key and/or secret_key is nil" do
      assert Key.authenticate("access_key", nil) == false
      assert Key.authenticate(nil, "secret_key") == false
      assert Key.authenticate(nil, nil) == false
    end
  end

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at(Key)
  end

  describe "delete/1" do
    test_delete_causes_record_deleted(Key)
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted(Key)
  end
end
