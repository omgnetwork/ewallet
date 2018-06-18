defmodule LocalLedgerDB.Transaction do
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
    field(:encrypted_metadata, Cloak.EncryptedMapField, default: %{})
    field(:encryption_version, :binary)
    field(:idempotency_token, :string)

    has_many(
      :entries,
      Entry,
      foreign_key: :transaction_uuid,
      references: :uuid
    )

    timestamps()
  end

  @doc """
  Validate the transaction and associated entries. cast_assoc will take care of
  setting the tranasction_uuid on all the entries.
  """
  def changeset(%Transaction{} = transaction, attrs) do
    transaction
    |> cast(attrs, [:metadata, :encrypted_metadata, :encryption_version, :idempotency_token])
    |> validate_required([:idempotency_token, :metadata, :encrypted_metadata])
    |> cast_assoc(:entries, required: true)
    |> unique_constraint(:idempotency_token)
    |> put_change(:encryption_version, Cloak.version())
  end

  @doc """
  Retrieve all transactions.
  """
  def all do
    Repo.all(
      from(
        t in Transaction,
        join: e in assoc(t, :entries),
        preload: [entries: e]
      )
    )
  end

  @doc """
  Retrieve a specific transaction and preload the associated entries.
  """
  def one(uuid) do
    Repo.one!(
      from(
        t in Transaction,
        join: e in assoc(t, :entries),
        where: t.uuid == ^uuid,
        preload: [entries: e]
      )
    )
  end

  @doc """
  Get a transaction using one or more fields.
  """
  @spec get_by(keyword() | map(), keyword()) :: %Transaction{} | nil
  def get_by(map, opts \\ []) do
    query = Transaction |> Repo.get_by(map)

    case opts[:preload] do
      nil -> query
      preload -> Repo.preload(query, preload)
    end
  end

  @doc """
  Helper function to get a transaction with an idempotency token and loads all the required
  associations.
  """
  @spec get_by_idempotency_token(String.t()) :: %Transaction{} | nil
  def get_by_idempotency_token(idempotency_token) do
    get_by(
      %{
        idempotency_token: idempotency_token
      },
      preload: [:entries]
    )
  end

  def get_or_insert(%{idempotency_token: idempotency_token} = attrs) do
    case get_by_idempotency_token(idempotency_token) do
      nil ->
        insert(attrs)

      transaction ->
        {:ok, transaction}
    end
  end

  @doc """
  Insert a transction and its entries.
  """
  def insert(attrs) do
    opts = [on_conflict: :nothing, conflict_target: :idempotency_token]

    %Transaction{}
    |> changeset(attrs)
    |> do_insert(opts)
  end

  defp do_insert(changeset, opts) do
    case Repo.insert(changeset, opts) do
      {:ok, transaction} ->
        transaction.idempotency_token
        |> get_by_idempotency_token()
        |> handle_retrieval_result()

      changeset ->
        changeset
    end
  end

  defp handle_retrieval_result(nil) do
    {:error, :inserted_entry_could_not_be_loaded}
  end

  defp handle_retrieval_result(transaction) do
    {:ok, transaction}
  end
end
