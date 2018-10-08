defmodule EWalletDB.Setting do
  @moduledoc """
  Ecto Schema representing settings.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset}
  alias Ecto.UUID
  alias EWalletDB.{Repo, Setting}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "setting" do
    external_id(prefix: "stg_")

    field(:key, :string)
    field(:value, :string)

    timestamps()
  end

  defp changeset(%Setting{} = setting, attrs) do
    setting
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint(:key)
  end

  @doc """
  Creates a new setting with the passed attributes.
  """
  def insert(attrs) do
    %Setting{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves a setting by its string name.
  """
  def get(key) when is_binary(key) do
    Repo.get_by(Setting, key: key)
  end

  def get(_), do: nil
end
