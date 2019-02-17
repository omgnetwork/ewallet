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

defmodule EWalletDB.APIKeyTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias Ecto.UUID
  alias EWalletDB.{APIKey, Repo}
  alias ActivityLogger.System

  @owner_app :some_app

  describe "APIKey factory" do
    test_has_valid_factory(APIKey)
  end

  describe "query_all/0" do
    test "returns a query for all API keys excluding the soft-deleted ones" do
      originator = insert(:user)

      api_key_1 = insert(:api_key)
      api_key_2 = insert(:api_key)
      api_key_3 = insert(:api_key)

      {:ok, _} = APIKey.delete(api_key_2, originator)

      query = APIKey.query_all()
      records = Repo.all(query)

      assert Enum.count(records) == 2
      assert Enum.any?(records, fn r -> r.id == api_key_1.id end)
      refute Enum.any?(records, fn r -> r.id == api_key_2.id end)
      assert Enum.any?(records, fn r -> r.id == api_key_3.id end)
    end
  end

  describe "get/1" do
    test "accepts a uuid" do
      api_key = insert(:api_key)
      result = APIKey.get(api_key.id)
      assert result.uuid == api_key.uuid
    end

    test "does not return a soft-deleted API key" do
      {:ok, api_key} = :api_key |> insert() |> APIKey.delete(%System{})
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
    test_insert_generate_uuid(APIKey, :uuid)
    test_insert_generate_external_id(APIKey, :id, "api_")
    test_insert_generate_timestamps(APIKey)
    # 32 bytes = ceil(32 / 3 * 4)
    test_insert_generate_length(APIKey, :key, 43)

    test_insert_allow_duplicate(APIKey, :account, insert(:account))
    test_insert_prevent_duplicate(APIKey, :key)

    test "defaults to master account if not provided" do
      master_account = get_or_insert_master_account()
      {:ok, api_key} = :api_key |> params_for(%{account: nil}) |> APIKey.insert()

      assert api_key.account_uuid == master_account.uuid
    end
  end

  describe "APIKey.update/2" do
    test_update_ignores_changing(APIKey, :key)
    test_update_ignores_changing(APIKey, :owner_app)

    test_update_field_ok(APIKey, :enabled, true, false)

    test_update_field_ok(
      APIKey,
      :exchange_address,
      insert(:wallet).address,
      insert(:wallet).address
    )

    test "update enable state with `expired`" do
      {:ok, api_key} = APIKey.insert(params_for(:api_key))
      assert api_key.enabled == true

      {:ok, api_key} =
        APIKey.update(api_key, %{
          "expired" => true,
          "originator" => %System{}
        })

      assert api_key.enabled == false
    end
  end

  describe "enable_or_disable/2" do
    test "disable an api key successfuly" do
      {:ok, key} = APIKey.insert(params_for(:api_key))
      assert key.enabled == true

      {:ok, updated} =
        APIKey.enable_or_disable(key, %{
          enabled: false,
          originator: %System{}
        })

      assert updated.enabled == false
    end

    test "disabling an api key twice doesn't re-enable it" do
      {:ok, key} = APIKey.insert(params_for(:api_key))
      assert key.enabled == true

      {:ok, updated1} =
        APIKey.enable_or_disable(key, %{
          enabled: false,
          originator: %System{}
        })

      assert updated1.enabled == false

      {:ok, updated2} =
        APIKey.enable_or_disable(key, %{
          enabled: false,
          originator: %System{}
        })

      assert updated2.enabled == false
    end

    test "enable an api key successfuly" do
      {:ok, key} =
        APIKey.insert(
          params_for(:api_key, %{
            enabled: false,
            originator: %System{}
          })
        )

      assert key.enabled == false

      {:ok, updated} =
        APIKey.enable_or_disable(key, %{
          enabled: true,
          originator: %System{}
        })

      assert updated.enabled == true
    end
  end

  describe "APIKey.authenticate/2" do
    test "returns the API key" do
      account = insert(:account)

      :api_key
      |> params_for(%{
        key: "apikey123",
        account: account,
        owner_app: Atom.to_string(@owner_app)
      })
      |> APIKey.insert()

      assert APIKey.authenticate("apikey123", @owner_app).account_uuid == account.uuid
    end

    test "returns false if API key does not exists" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert()

      assert APIKey.authenticate("unmatched", @owner_app) == false
    end

    test "returns false if API key exists but for a different owner app" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: "wrong_app"})
      |> APIKey.insert()

      assert APIKey.authenticate("unmatched", @owner_app) == false
    end

    test "returns false if API key is nil" do
      assert APIKey.authenticate(nil, @owner_app) == false
    end
  end

  describe "APIKey.authenticate/3" do
    test "returns the API key if the api_key_id and api_key matches database" do
      account = insert(:account)

      {:ok, api_key} =
        :api_key
        |> params_for(%{
          key: "apikey123",
          account: account,
          owner_app: Atom.to_string(@owner_app)
        })
        |> APIKey.insert()

      assert APIKey.authenticate(api_key.id, api_key.key, @owner_app).account_uuid == account.uuid
    end

    test "returns false if API key does not exists" do
      key_id = UUID.generate()

      :api_key
      |> params_for(%{id: key_id, key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert()

      assert APIKey.authenticate(key_id, "unmatched", @owner_app) == false
    end

    test "returns false if API key ID does not exists" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert()

      assert APIKey.authenticate(UUID.generate(), "apikey123", @owner_app) == false
    end

    test "returns false if API key ID and its key exist but for a different owner app" do
      key_id = UUID.generate()

      :api_key
      |> params_for(%{key: "apikey123", owner_app: "wrong_app"})
      |> APIKey.insert()

      assert APIKey.authenticate(key_id, "apikey123", @owner_app) == false
    end

    test "returns false if API key ID is not provided" do
      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert()

      assert APIKey.authenticate(nil, "apikey123", @owner_app) == false
    end

    test "returns false if API key is not provided" do
      key_id = UUID.generate()

      :api_key
      |> params_for(%{key: "apikey123", owner_app: Atom.to_string(@owner_app)})
      |> APIKey.insert()

      assert APIKey.authenticate(key_id, nil, @owner_app) == false
    end
  end

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at(APIKey)
  end

  describe "delete/1" do
    test_delete_causes_record_deleted(APIKey)
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted(APIKey)
  end
end
