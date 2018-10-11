defmodule EWalletDB.StoredSetting do
  @moduledoc """
  Ecto Schema representing stored settings.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.Changeset
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.StoredSetting

  @primary_key {:uuid, UUID, autogenerate: true}
  @types [
    "string",
    "integer",
    "map",
    "boolean",
    "array",
    "select"
  ]
  def types, do: @types

  schema "setting" do
    external_id(prefix: "stg_")

    field(:key, :string)
    field(:data, :map)
    field(:encrypted_data, EWalletDB.Encrypted.Map)
    field(:type, :string)
    field(:options, :string)
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
      :parent,
      :parent_value,
      :options,
      :secret,
      :position
    ])
    |> validate_required([:key, :type, :position])
    |> validate_inclusion(:type, @types)
    |> validate_required_exclusive([:data, :encrypted_data])
    |> unique_constraint(:key)
  end
end
