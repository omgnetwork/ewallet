defmodule EWalletDB.APIKeyTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.APIKey
  alias Ecto.UUID

  @owner_app :some_app

  describe "APIKey factory" do
    test_has_valid_factory APIKey
  end

  describe "get/1" do
    test "accepts a uuid" do
      api_key = insert(:api_key)
      result = APIKey.get(api_key.id)
      assert result.id == api_key.id
    end

    test "does not return a soft-deleted API key" do
      {:ok, api_key} = :api_key |> insert() |> APIKey.delete()
      assert APIKey.get(api_key.id) == nil
    end

    test "returns nil if the given uuid is invalid" do
      assert APIKey.get("not_a_uuid") == nil
    end

    test "returns nil if the key with the given uuid is not found" do
      assert APIKey.get(UUID.generate()) == nil
    end
  end

  describe "APIKey.insert/1" do
    test_insert_generate_uuid APIKey, :id
    test_insert_generate_external_id APIKey, :external_id, "api_"
    test_insert_generate_timestamps APIKey
    test_insert_generate_length APIKey, :key, 43 # 32 bytes = ceil(32 / 3 * 4)

    test_insert_allow_duplicate APIKey, :account, insert(:account)
    test_insert_prevent_duplicate APIKey, :key

    test "defaults to master account if not provided" do
      master_account = get_or_insert_master_account()
      {:ok, api_key} = :api_key |> params_for(%{account: nil}) |> APIKey.insert()

      assert api_key.account_id == master_account.id
    end
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

      assert APIKey.authenticate("apikey123", @owner_app).id == account.id
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

      assert APIKey.authenticate(api_key.id, api_key.key, @owner_app).id == account.id
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

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at APIKey
  end

  describe "delete/1" do
    test_delete_causes_record_deleted APIKey
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted APIKey
  end
end
