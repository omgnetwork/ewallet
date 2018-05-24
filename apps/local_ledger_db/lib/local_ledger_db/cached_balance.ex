defmodule LocalLedgerDB.CachedBalance do
  @moduledoc """
  Ecto Schema representing a cached balance.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias LocalLedgerDB.{Repo, Wallet, CachedBalance}

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "cached_balance" do
    field(:amounts, :map)
    field(:computed_at, :naive_datetime)

    belongs_to(
      :wallet,
      Wallet,
      foreign_key: :wallet_address,
      references: :address,
      type: :string
    )

    timestamps()
  end

  @doc """
  Validate the cached balance attributes.
  """
  def changeset(%CachedBalance{} = balance, attrs) do
    balance
    |> cast(attrs, [:amounts, :wallet_address, :computed_at])
    |> validate_required([:amounts, :wallet_address, :computed_at])
    |> foreign_key_constraint(:wallet_address)
  end

  @doc """
  Retrieve a cached balance using the specified address.
  """
  def get(address) do
    CachedBalance
    |> where([c], c.wallet_address == ^address)
    |> order_by([c], desc: c.computed_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Insert a cached balance.
  """
  def insert(attrs) do
    %CachedBalance{}
    |> CachedBalance.changeset(attrs)
    |> Repo.insert()
  end
end
