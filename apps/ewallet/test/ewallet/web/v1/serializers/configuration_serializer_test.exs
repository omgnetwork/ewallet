# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.ConfigurationSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias Ecto.UUID
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.ConfigurationSerializer
  alias EWalletConfig.Factory, as: ConfigFactory
  alias EWalletConfig.{Setting, StoredSetting}
  alias ExULID.ULID

  setup do
    :ok = Sandbox.checkout(EWalletConfig.Repo)
  end

  describe "serialize/1 with EWalletConfig.StoredSetting" do
    test "serializes a configuration into the correct response format" do
      stored_setting = ConfigFactory.insert(:stored_setting)

      expected = %{
        object: "configuration",
        id: stored_setting.id,
        key: stored_setting.key,
        value: stored_setting.data.value,
        type: stored_setting.type,
        description: stored_setting.description,
        options: stored_setting.options,
        parent: stored_setting.parent,
        parent_value: stored_setting.parent_value,
        secret: stored_setting.secret,
        position: stored_setting.position,
        created_at: Date.to_iso8601(stored_setting.inserted_at),
        updated_at: Date.to_iso8601(stored_setting.updated_at)
      }

      assert ConfigurationSerializer.serialize(stored_setting) == expected
    end
  end

  describe "serialize/1 with EWalletConfig.Setting" do
    setup do
      setting = %Setting{
        uuid: UUID.generate(),
        id: "stg_" <> ULID.generate(),
        key: "some_setting_key",
        value: "some_setting_value",
        type: "string",
        description: "Some setting description",
        options: ["some_setting_value", "another_allowed_value"],
        parent: nil,
        parent_value: nil,
        secret: false,
        position: 99,
        inserted_at: NaiveDateTime.utc_now(),
        updated_at: NaiveDateTime.utc_now()
      }

      %{setting: setting}
    end

    test "serializes a configuration into the correct response format", context do
      expected = %{
        object: "configuration",
        id: context.setting.id,
        key: context.setting.key,
        value: context.setting.value,
        type: context.setting.type,
        description: context.setting.description,
        options: context.setting.options,
        parent: context.setting.parent,
        parent_value: context.setting.parent_value,
        secret: context.setting.secret,
        position: context.setting.position,
        created_at: Date.to_iso8601(context.setting.inserted_at),
        updated_at: Date.to_iso8601(context.setting.updated_at)
      }

      assert ConfigurationSerializer.serialize(context.setting) == expected
    end

    test "serializes to nil if the configuration is not loaded" do
      assert ConfigurationSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes nil to nil" do
      assert ConfigurationSerializer.serialize(nil) == nil
    end

    test "serializes a configuration paginator into a list object", context do
      setting_1 = %{
        context.setting
        | uuid: UUID.generate(),
          id: "stg_" <> ULID.generate(),
          key: "some_setting_1"
      }

      setting_2 = %{
        context.setting
        | uuid: UUID.generate(),
          id: "stg_" <> ULID.generate(),
          key: "some_setting_2"
      }

      paginator = %Paginator{
        data: [setting_1, setting_2],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          ConfigurationSerializer.serialize(setting_1),
          ConfigurationSerializer.serialize(setting_2)
        ],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert ConfigurationSerializer.serialize(paginator) == expected
    end
  end

  describe "serialize_with_errors/1" do
    test "returns a map of settings keys and their updated values or errors" do
      stored_setting = ConfigFactory.insert(:stored_setting)
      invalid_changeset = StoredSetting.update_changeset(stored_setting, %{})

      update_result = [
        {stored_setting.key, {:ok, stored_setting}},
        {"config_two", {:error, invalid_changeset}},
        {"config_three", {:error, :setting_not_found}}
      ]

      expected = %{
        object: "map",
        data: %{
          "setting_key1" => ConfigurationSerializer.serialize(stored_setting),
          "config_two" => %{
            object: "error",
            code: "client:invalid_parameter",
            description: "Invalid parameter provided. `originator` can't be blank.",
            messages: %{"originator" => [:required]}
          },
          "config_three" => %{
            object: "error",
            code: "setting:not_found",
            description: "The setting could not be inserted.",
            messages: nil
          }
        }
      }

      assert ConfigurationSerializer.serialize_with_errors(update_result) == expected
    end

    test "serializes to nil if the configuration is not loaded" do
      assert ConfigurationSerializer.serialize_with_errors(%NotLoaded{}) == nil
    end

    test "serializes nil to nil" do
      assert ConfigurationSerializer.serialize_with_errors(nil) == nil
    end
  end
end
