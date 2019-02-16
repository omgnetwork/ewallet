# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletConfig.StoredSetting do
  @moduledoc """
  Ecto Schema representing stored settings.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.Changeset
  import EWalletConfig.{Validator, SettingValidator}
  alias Ecto.UUID
  alias EWalletConfig.StoredSetting

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  @types [
    "string",
    "integer",
    "unsigned_integer",
    "map",
    "boolean",
    "array"
  ]
  def types, do: @types

  schema "setting" do
    external_id(prefix: "stg_")

    field(:key, :string)
    field(:data, :map)
    field(:encrypted_data, EWalletConfig.Encrypted.Map)
    field(:type, :string)
    field(:description, :string)
    field(:options, :map)
    field(:parent, :string)
    field(:parent_value, :string)
    field(:secret, :boolean, default: false)
    field(:position, :integer)

    timestamps()
    activity_logging()
  end

  def changeset(%StoredSetting{} = setting, attrs) do
    setting
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :key,
        :data,
        :encrypted_data,
        :type,
        :description,
        :parent,
        :parent_value,
        :options,
        :secret,
        :position
      ],
      required: [
        :key,
        :type,
        :position
      ],
      encrypted: [:encrypted_data]
    )
    |> validate_immutable(:key)
    |> validate_inclusion(:type, @types)
    |> validate_required_exclusive([:data, :encrypted_data])
    |> unique_constraint(:key)
    |> validate_setting_type()
    |> validate_setting_with_options()
  end

  def update_changeset(%StoredSetting{} = setting, attrs) do
    setting
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :data,
        :encrypted_data,
        :description,
        :position
      ],
      encrypted: [:encrypted_data]
    )
    |> validate_required_exclusive([:data, :encrypted_data])
    |> validate_setting_type()
    |> validate_setting_with_options()
  end
end
