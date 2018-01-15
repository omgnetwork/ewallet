defmodule CaishenDB.Entry do
  @moduledoc """
  Ecto Schema representing entries. An entry is used to group a set of
  transactions (debits/credits).
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias CaishenDB.{Repo, Entry, Transaction}

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "entry" do
    field :metadata, Cloak.EncryptedMapField
    field :encryption_version, :binary
    field :correlation_id, :string
    has_many :transactions, Transaction

    timestamps()
  end

  @doc """
  Validate the entry and associated transactions. cast_assoc will take care of
  setting the entry_id on all the transactions.
  """
  def changeset(%Entry{} = entry, attrs) do
    entry
    |> cast(attrs, [:metadata, :encryption_version, :correlation_id])
    |> validate_required([:correlation_id])
    |> cast_assoc(:transactions, required: true)
    |> unique_constraint(:correlation_id)
    |> put_change(:encryption_version, Cloak.version)
  end

  @doc """
  Retrieve all entries.
  """
  def all do
    Repo.all from e in Entry,
             join: t in assoc(e, :transactions),
             preload: [transactions: t]
  end

  def get_with_correlation_id(correlation_id) do
    Repo.one! from e in Entry,
              join: t in assoc(e, :transactions),
              where: e.correlation_id == ^correlation_id,
              preload: [transactions: t]
  end

  @doc """
  Retrieve a specific entry and preload the associated transactions.
  """
  def one(id) do
    Repo.one! from e in Entry,
              join: t in assoc(e, :transactions),
              where: e.id == ^id,
              preload: [transactions: t]
  end

  @doc """
  Insert an entry and its transactions.
  """
  def insert(attrs) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert
  end
end
