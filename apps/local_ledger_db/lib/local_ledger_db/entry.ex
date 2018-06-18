defmodule LocalLedgerDB.Entry do
  @moduledoc """
  Ecto Schema representing entries. An entry is used to group a set of
  transactions (debits/credits).
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias LocalLedgerDB.{Repo, Entry, Transaction}

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "transaction" do
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, LocalLedgerDB.Encrypted.Map, default: %{})
    field(:idempotency_token, :string)

    has_many(
      :transactions,
      Transaction,
      foreign_key: :transaction_uuid,
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
    |> cast(attrs, [:metadata, :encrypted_metadata, :idempotency_token])
    |> validate_required([:idempotency_token, :metadata, :encrypted_metadata])
    |> cast_assoc(:transactions, required: true)
    |> unique_constraint(:idempotency_token)
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
  Get a entry using one or more fields.
  """
  @spec get_by(keyword() | map(), keyword()) :: %Entry{} | nil
  def get_by(map, opts \\ []) do
    query = Entry |> Repo.get_by(map)

    case opts[:preload] do
      nil -> query
      preload -> Repo.preload(query, preload)
    end
  end

  @doc """
  Helper function to get a entry with an idempotency token and loads all the required
  associations.
  """
  @spec get_by_idempotency_token(String.t()) :: %Entry{} | nil
  def get_by_idempotency_token(idempotency_token) do
    get_by(
      %{
        idempotency_token: idempotency_token
      },
      preload: [:transactions]
    )
  end

  def get_or_insert(%{idempotency_token: idempotency_token} = attrs) do
    case get_by_idempotency_token(idempotency_token) do
      nil ->
        insert(attrs)

      entry ->
        {:ok, entry}
    end
  end

  @doc """
  Insert an entry and its transactions.
  """
  def insert(attrs) do
    opts = [on_conflict: :nothing, conflict_target: :idempotency_token]

    %Entry{}
    |> changeset(attrs)
    |> do_insert(opts)
  end

  defp do_insert(changeset, opts) do
    case Repo.insert(changeset, opts) do
      {:ok, entry} ->
        entry.idempotency_token
        |> get_by_idempotency_token()
        |> handle_retrieval_result()

      changeset ->
        changeset
    end
  end

  defp handle_retrieval_result(nil) do
    {:error, :inserted_transaction_could_not_be_loaded}
  end

  defp handle_retrieval_result(entry) do
    {:ok, entry}
  end
end
