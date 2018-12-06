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
  @types [
    "string",
    "integer",
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
      ]
    )
    |> validate_immutable(:key)
    |> validate_inclusion(:type, @types)
    |> validate_required_exclusive([:data, :encrypted_data])
    |> unique_constraint(:key)
    |> validate_type()
    |> validate_with_options()
  end

  def update_changeset(%StoredSetting{} = setting, attrs) do
    setting
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :data,
        :encrypted_data,
        :description
      ]
    )
    |> validate_required_exclusive([:data, :encrypted_data])
    |> validate_type(setting)
    |> validate_with_options(setting)
  end
end
