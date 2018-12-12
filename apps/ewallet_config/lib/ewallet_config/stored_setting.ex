defmodule EWalletConfig.StoredSetting do
  @moduledoc """
  Ecto Schema representing stored settings.
  """
  use Ecto.Schema
  use EWalletConfig.Types.ExternalID
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
  end

  def changeset(%StoredSetting{} = setting, attrs) do
    setting
    |> cast(attrs, [
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
    ])
    |> validate_required([:key, :type, :position])
    |> validate_immutable(:key)
    |> validate_inclusion(:type, @types)
    |> validate_required_exclusive([:data, :encrypted_data])
    |> unique_constraint(:key)
    |> validate_type()
    |> validate_with_options()
    |> validate_positive_integer()
  end

  def update_changeset(%StoredSetting{} = setting, attrs) do
    setting
    |> cast(attrs, [
      :data,
      :encrypted_data,
      :description,
      :position
    ])
    |> validate_required_exclusive([:data, :encrypted_data])
    |> validate_type(setting)
    |> validate_with_options(setting)
    |> validate_positive_integer(setting)
  end
end
