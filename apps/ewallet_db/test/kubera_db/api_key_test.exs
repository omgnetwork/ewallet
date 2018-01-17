defmodule EWalletDB.APIKeyTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.APIKey
  alias Ecto.UUID

  @owner_app :some_app

  describe "APIKey factory" do
    test_has_valid_factory APIKey
  end

  describe "APIKey.insert/1" do
    test_insert_generate_uuid APIKey, :id
    test_insert_generate_timestamps APIKey
    test_insert_generate_length APIKey, :key, 43

    test_insert_allow_duplicate APIKey, :account, insert(:account)
    test_insert_prevent_blank_assoc APIKey, :account
    test_insert_prevent_duplicate APIKey, :key
  end

  describe "APIKey.authenticate/2" do
    test "returns the associated account if exists" do
      account = insert(:account)

      :api_key
      |> params_for(%{
        key: "apikey123",
        account: account,
        owner_app: Atom.to_string(@owner_app)
      })
      |> APIKey.insert

      assert APIKey.authenticate("apikey123", @owner_app) == account
    end

    test "returns false if API key does not exists" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert

      assert APIKey.authenticate("unmatched", @owner_app) == false
    end

    test "returns false if API key exists but for a different owner app" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: "wrong_app"})
      |> APIKey.insert

      assert APIKey.authenticate("unmatched", @owner_app) == false
    end

    test "returns false if API key is nil" do
      assert APIKey.authenticate(nil, @owner_app) == false
    end
  end

  describe "APIKey.authenticate/3" do
    test "returns the account if the api_key_id and api_key matches database" do
      account = insert(:account)

      {:ok, api_key} =
        :api_key
        |> params_for(%{
          key: "apikey123",
          account: account,
          owner_app: Atom.to_string(@owner_app)
        })
        |> APIKey.insert

      assert APIKey.authenticate(api_key.id, api_key.key, @owner_app) == account
    end

    test "returns false if API key does not exists" do
      key_id = UUID.generate

      :api_key
      |> params_for(%{id: key_id, key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert

      assert APIKey.authenticate(key_id, "unmatched", @owner_app) == false
    end

    test "returns false if API key ID does not exists" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert

      assert APIKey.authenticate(UUID.generate, "apikey123", @owner_app) == false
    end

    test "returns false if API key ID and its key exist but for a different owner app" do
      key_id = UUID.generate

      :api_key
      |> params_for(%{key: "apikey123", owner_app: "wrong_app"})
      |> APIKey.insert

      assert APIKey.authenticate(key_id, "apikey123", @owner_app) == false
    end

    test "returns false if API key ID is not provided" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert

      assert APIKey.authenticate(nil, "apikey123", @owner_app) == false
    end

    test "returns false if API key is not provided" do
      key_id = UUID.generate

      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert

      assert APIKey.authenticate(key_id, nil, @owner_app) == false
    end
  end
end
