defmodule KuberaDB.KeyTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.Key

  describe "Key factory" do
    test_has_valid_factory Key
  end

  describe "insert/1" do
    test_insert_generate_uuid Key, :id
    test_insert_generate_timestamps Key
    test_insert_generate_length Key, :access_key, 43
    test_insert_generate_length Key, :secret_key, 43

    test_insert_prevent_blank_assoc Key, :account
    test_insert_prevent_duplicate Key, :access_key

    test "hashes secret_key with bcrypt before saving" do
      {res, key} = Key.insert(params_for(:key, %{secret_key: "my_secret"}))

      assert res == :ok
      assert "$2b$" <> _ = key.secret_key_hash
      refute key.secret_key == key.secret_key_hash
    end

    test "does not save secret_key to database" do
      {:ok, key} = Key.insert(params_for(:key))
      assert Repo.get(Key, key.id).secret_key == nil
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
      |> Key.insert

      auth_account = Key.authenticate("access123", "secret321")
      assert auth_account.id == account.id
    end

    test "returns nil if access_key and/or secret_key do not match" do
      :key
      |> params_for(%{access_key: "access123", secret_key: "secret321"})
      |> Key.insert

      assert Key.authenticate("access123", "unmatched") == false
      assert Key.authenticate("unmatched", "secret321") == false
      assert Key.authenticate("unmatched", "unmatched") == false
    end

    test "returns nil if access_key and/or secret_key is nil" do
      assert Key.authenticate("access_key", nil) == false
      assert Key.authenticate(nil, "secret_key") == false
      assert Key.authenticate(nil, nil) == false
    end
  end
end
