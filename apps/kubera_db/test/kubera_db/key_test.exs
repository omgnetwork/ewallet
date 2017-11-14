defmodule KuberaDB.KeyTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias KuberaDB.{Repo, Key}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "factory" do
    test "has a valid factory" do
      {res, _key} = Key.insert(params_for(:key))
      assert res == :ok
    end
  end

  describe "insert/1" do
    test "generates a UUID in place of a regular ID" do
      {res, key} = :key |> params_for |> Key.insert

      assert res == :ok
      assert String.match?(key.id,
        ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, key} = :key |> params_for |> Key.insert

      assert res == :ok
      assert key.inserted_at != nil
      assert key.updated_at != nil
    end

    test "prevents creation of a key without account specified" do
      {result, changeset} =
        :key
        |> params_for(%{account: ""})
        |> Key.insert

      assert result == :error
      assert changeset.errors ==
        [account_id: {"can't be blank", [validation: :required]}]
    end

    test "generates access_key with length == 43 if not provided" do
      {result, key} =
        :key
        |> params_for(%{access_key: nil})
        |> Key.insert

      assert result == :ok
      assert String.length(key.access_key) == 43
    end

    test "generates secret_key with length == 43 if not provided" do
      {result, key} =
        :key
        |> params_for(%{secret_key: nil})
        |> Key.insert

      assert result == :ok
      assert String.length(key.secret_key) == 43
    end

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

    test "returns error if same access key already exists" do
      {:ok, _} =
        :key
        |> params_for(%{access_key: "same_access"})
        |> Key.insert

      {result, changeset} =
        :key
        |> params_for(%{access_key: "same_access"})
        |> Key.insert

      assert result == :error
      assert changeset.errors == [access_key: {"has already been taken", []}]
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
