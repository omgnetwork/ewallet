defmodule LocalLedgerDB.MintedToken do
  @moduledoc """
  Ecto Schema representing minted tokens. Minted tokens are made up of an
  id (e.g. OMG) and the associated UUID in eWallet DB.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias LocalLedgerDB.{Repo, MintedToken, Transaction}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "minted_token" do
    field(:id, :string)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, Cloak.EncryptedMapField, default: %{})
    field(:encryption_version, :binary)

    has_many(
      :transactions,
      Transaction,
      foreign_key: :minted_token_id,
      references: :id
    )

    timestamps()
  end

  @doc """
  Validate the minted token attributes.
  """
  def changeset(%MintedToken{} = minted_token, attrs) do
    minted_token
    |> cast(attrs, [:id, :metadata, :encrypted_metadata, :encryption_version])
    |> validate_required([:id, :metadata, :encrypted_metadata])
    |> unique_constraint(:id)
    |> put_change(:encryption_version, Cloak.version())
  end

  @doc """
  Retrieve a minted token from the database using the specified id
  or insert a new one before returning it.
  """
  def get_or_insert(%{"id" => id} = attrs) do
    case get(id) do
      nil ->
        insert(attrs)

      minted_token ->
        {:ok, minted_token}
    end
  end

  @doc """
  Retrieve a minted token using the specified id.
  """
  def get(id) do
    Repo.get_by(MintedToken, id: id)
  end

  @doc """
  Create a new minted token with the passed attributes. With
  "on conflict: nothing", conflicts are ignored. No matter what, a fresh get
  query is made to get the current database record, be it the one inserted right
  before or one inserted by another concurrent process.
  """
  def insert(%{"id" => id} = attrs) do
    changeset = MintedToken.changeset(%MintedToken{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :id]

    case Repo.insert(changeset, opts) do
      {:ok, _minted_token} ->
        {:ok, get(id)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
