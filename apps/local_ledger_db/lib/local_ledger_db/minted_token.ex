defmodule LocalLedgerDB.MintedToken do
  @moduledoc """
  Ecto Schema representing minted tokens. Minted tokens are made up of a
  friendly_id (e.g. MNT) and the associated ID in Kubera DB.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias LocalLedgerDB.{Repo, MintedToken, Transaction}

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "minted_token" do
    field :friendly_id, :string
    field :metadata, Cloak.EncryptedMapField
    field :encryption_version, :binary
    has_many :transactions, Transaction
    timestamps()
  end

  @doc """
  Validate the minted token attributes.
  """
  def changeset(%MintedToken{} = minted_token, attrs) do
    minted_token
    |> cast(attrs, [:friendly_id, :metadata, :encryption_version])
    |> validate_required([:friendly_id])
    |> unique_constraint(:friendly_id)
    |> put_change(:encryption_version, Cloak.version)
  end

  @doc """
  Retrieve a minted token from the database using the specified friendly_id
  or insert a new one before returning it.
  """
  def get_or_insert(%{"friendly_id" => friendly_id, "metadata" => _} = attrs) do
    case get(friendly_id) do
      nil ->
        insert(attrs)
      minted_token ->
        {:ok, minted_token}
    end
  end

  @doc """
  Retrieve a minted token using the specified friendly_id.
  """
  def get(friendly_id) do
    Repo.get_by(MintedToken, friendly_id: friendly_id)
  end

  @doc """
  Create a new minted token with the passed attributes. With
  "on conflict: nothing", conflicts are ignored. No matter what, a fresh get
  query is made to get the current database record, be it the one inserted right
  before or one inserted by another concurrent process.
  """
  def insert(%{"friendly_id" => friendly_id, "metadata" => _} = attrs) do
    changeset = MintedToken.changeset(%MintedToken{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :friendly_id]

    case Repo.insert(changeset, opts) do
      {:ok, _minted_token} ->
        {:ok, get(friendly_id)}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
