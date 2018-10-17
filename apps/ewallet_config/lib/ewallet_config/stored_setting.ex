defmodule EWalletConfig.StoredSetting do
  @moduledoc """
  Ecto Schema representing stored settings.
  """
  use Ecto.Schema
  use EWalletConfig.Types.ExternalID
  import Ecto.Changeset
  import EWalletConfig.Validator
  alias Ecto.UUID
  alias EWalletConfig.StoredSetting

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
    field(:encrypted_data, EWalletConfig.Encrypted.Map)
    field(:type, :string)
    field(:description, :string)
    field(:options, :string)
    field(:parent, :string)
    field(:parent_value, :string)
    field(:secret, :boolean, default: false)
    field(:position, :integer)

    timestamps()
  end

  # TODO: Validate inclusion for select type
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
  end
end
