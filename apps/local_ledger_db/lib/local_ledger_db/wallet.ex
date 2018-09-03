defmodule LocalLedgerDB.Wallet do
  @moduledoc """
  Ecto Schema representing wallets. A balance is made up of a unique address
  and the ID associated with it in eWallet DB.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias LocalLedger.{EctoBatchStream}
  alias LocalLedgerDB.{Entry, Repo, Wallet}

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "wallet" do
    field(:address, :string)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, LocalLedgerDB.Encrypted.Map, default: %{})

    has_many(
      :entries,
      Entry,
      foreign_key: :wallet_address,
      references: :address
    )

    timestamps()
  end

  @doc """
  Validate the balance attributes.
  """
  def changeset(%Wallet{} = balance, attrs) do
    balance
    |> cast(attrs, [:address, :metadata, :encrypted_metadata])
    |> validate_required([:address, :metadata, :encrypted_metadata])
    |> unique_constraint(:address)
  end

  @doc """
  Batch load wallets and run the callback for each balance.
  """
  def stream_all(callback) do
    Repo
    |> EctoBatchStream.stream(Wallet)
    |> Enum.each(callback)
  end

  @doc """
  Update the updated_at field for all wallets matching the given addresses.
  """
  def touch(addresses) do
    updated_at =
      Ecto.DateTime.utc()
      |> Ecto.DateTime.to_iso8601()

    Repo.update_all(
      from(b in Wallet, where: b.address in ^addresses),
      set: [updated_at: updated_at]
    )
  end

  @doc """
  Use a FOR UPDATE lock on the balance records for which the current wallets
  will be calculated.
  """
  def lock(addresses) do
    Repo.all(
      from(
        b in Wallet,
        where: b.address in ^addresses,
        lock: "FOR UPDATE"
      )
    )
  end

  @doc """
  Retrieve a balance from the database using the specified address
  or insert a new one before returning it.
  """
  def get_or_insert(%{"address" => address} = attrs) do
    case get(address) do
      nil ->
        insert(attrs)

      balance ->
        {:ok, balance}
    end
  end

  @doc """
  Retrieve a balance using the specified address.
  """
  def get(address) do
    Repo.get_by(Wallet, address: address)
  end

  @doc """
  Create a new balance with the passed attributes.  With
  "on conflict: nothing", conflicts are ignored. No matter what, a fresh get
  query is made to get the current database record, be it the one inserted right
  before or one inserted by another concurrent process.
  """
  def insert(%{"address" => address} = attrs) do
    changeset = Wallet.changeset(%Wallet{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :address]

    case Repo.insert(changeset, opts) do
      {:ok, _balance} ->
        {:ok, get(address)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
