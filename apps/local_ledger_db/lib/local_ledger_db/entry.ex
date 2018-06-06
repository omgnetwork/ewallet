defmodule LocalLedgerDB.Entry do
  @moduledoc """
  Ecto Schema representing entries. An entry is used to group a set of
  transactions (debits/credits).
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias LocalLedgerDB.{Repo, Entry, Transaction}

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "entry" do
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, Cloak.EncryptedMapField, default: %{})
    field(:encryption_version, :binary)
    field(:idempotency_token, :string)

    has_many(
      :transactions,
      Transaction,
      foreign_key: :entry_uuid,
      references: :uuid
    )

    timestamps()
  end

  @doc """
  Validate the entry and associated transactions. cast_assoc will take care of
  setting the entry_uuid on all the transactions.
  """
  def changeset(%Entry{} = entry, attrs) do
    entry
    |> cast(attrs, [:metadata, :encrypted_metadata, :encryption_version, :idempotency_token])
    |> validate_required([:idempotency_token, :metadata, :encrypted_metadata])
    |> cast_assoc(:transactions, required: true)
    |> unique_constraint(:idempotency_token)
    |> put_change(:encryption_version, Cloak.version())
  end

  @doc """
  Retrieve all entries.
  """
  def all do
    Repo.all(
      from(
        e in Entry,
        join: t in assoc(e, :transactions),
        preload: [transactions: t]
      )
    )
  end

  def get_with_idempotency_token(idempotency_token) do
    Repo.one!(
      from(
        e in Entry,
        join: t in assoc(e, :transactions),
        where: e.idempotency_token == ^idempotency_token,
        preload: [transactions: t]
      )
    )
  end

  @doc """
  Retrieve a specific entry and preload the associated transactions.
  """
  def one(uuid) do
    Repo.one!(
      from(
        e in Entry,
        join: t in assoc(e, :transactions),
        where: e.uuid == ^uuid,
        preload: [transactions: t]
      )
    )
  end

  @doc """
  Insert an entry and its transactions.
  """
  def insert(attrs) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end
end
