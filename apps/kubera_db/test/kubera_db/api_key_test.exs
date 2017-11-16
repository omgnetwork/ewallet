defmodule KuberaDB.APIKeyTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.APIKey

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

  describe "APIKey.authenticate/1" do
    test "returns the associated account if exists" do
      account = insert(:account)

      :api_key
      |> params_for(%{key: "apikey123", account: account})
      |> APIKey.insert

      assert APIKey.authenticate("apikey123") == account
    end

    test "returns false if API key does not exists" do
      :api_key
      |> params_for(%{key: "apikey123"})
      |> APIKey.insert

      assert APIKey.authenticate("unmatched") == false
    end

    test "returns false if API key is nil" do
      assert APIKey.authenticate(nil) == false
    end
  end
end
