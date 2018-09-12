defmodule EWalletDB.Transaction do
  @moduledoc """
  Ecto Schema representing transactions.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  alias Ecto.{Multi, UUID}
  alias EWalletDB.{Account, ExchangePair, Repo, Token, Transaction, User, Wallet}

  @pending "pending"
  @confirmed "confirmed"
  @failed "failed"
  @statuses [@pending, @confirmed, @failed]
  def pending, do: @pending
  def confirmed, do: @confirmed
  def failed, do: @failed

  @internal "internal"
  @external "external"
  @types [@internal, @external]
  def internal, do: @internal
  def external, do: @external

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "transaction" do
    external_id(prefix: "txn_")

    field(:idempotency_token, :string)
    field(:from_amount, EWalletDB.Types.Integer)
    field(:to_amount, EWalletDB.Types.Integer)
    # pending -> confirmed
    field(:status, :string, default: @pending)
    # internal / external
    field(:type, :string, default: @internal)
    # Payload received from client
    field(:payload, EWalletDB.Encrypted.Map)
    # Response returned by ledger
    field(:local_ledger_uuid, :string)
    field(:error_code, :string)
    field(:error_description, :string)
    field(:error_data, :map)

    field(:rate, :float)
    field(:calculated_at, :naive_datetime)

    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, EWalletDB.Encrypted.Map, default: %{})

    belongs_to(
      :from_token,
      Token,
      foreign_key: :from_token_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :to_token,
      Token,
      foreign_key: :to_token_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :exchange_pair,
      ExchangePair,
      foreign_key: :exchange_pair_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :to_wallet,
      Wallet,
      foreign_key: :to,
      references: :address,
      type: :string
    )

    belongs_to(
      :from_wallet,
      Wallet,
      foreign_key: :from,
      references: :address,
      type: :string
    )

    belongs_to(
      :from_account,
      Account,
      foreign_key: :from_account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :to_account,
      Account,
      foreign_key: :to_account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :from_user,
      User,
      foreign_key: :from_user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :to_user,
      User,
      foreign_key: :to_user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :exchange_account,
      Account,
      foreign_key: :exchange_account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :exchange_wallet,
      Wallet,
      foreign_key: :exchange_wallet_address,
      references: :address,
      type: :string
    )

    timestamps()
  end

  defp changeset(%Transaction{} = transaction, attrs) do
    transaction
    |> cast(attrs, [
      :idempotency_token,
      :status,
      :type,
      :payload,
      :metadata,
      :encrypted_metadata,
      :from_account_uuid,
      :to_account_uuid,
      :from_user_uuid,
      :to_user_uuid,
      :from_token_uuid,
      :to_token_uuid,
      :from_amount,
      :to_amount,
      :exchange_account_uuid,
      :exchange_wallet_address,
      :to,
      :from,
      :rate,
      :local_ledger_uuid,
      :error_code,
      :error_description,
      :exchange_pair_uuid,
      :calculated_at
    ])
    |> validate_required([
      :idempotency_token,
      :status,
      :type,
      :payload,
      :from_amount,
      :from_token_uuid,
      :to_amount,
      :to_token_uuid,
      :to,
      :from,
      :metadata,
      :encrypted_metadata
    ])
    |> validate_number(:from_amount, less_than: 100_000_000_000_000_000_000_000_000_000_000_000)
    |> validate_number(:to_amount, less_than: 100_000_000_000_000_000_000_000_000_000_000_000)
    |> validate_from_wallet_identifier()
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:type, @types)
    |> validate_required_exclusive(%{
      from_user_uuid: nil,
      from_account_uuid: nil,
      from: Wallet.genesis_address()
    })
    |> validate_required_exclusive(%{
      to_user_uuid: nil,
      to_account_uuid: nil,
      to: Wallet.genesis_address()
    })
    |> validate_immutable(:idempotency_token)
    |> unique_constraint(:idempotency_token)
    |> assoc_constraint(:from_token)
    |> assoc_constraint(:to_token)
    |> assoc_constraint(:to_wallet)
    |> assoc_constraint(:from_wallet)
    |> assoc_constraint(:exchange_account)
  end

  defp confirm_changeset(%Transaction{} = transaction, attrs) do
    transaction
    |> cast(attrs, [:status, :local_ledger_uuid])
    |> validate_required([:status, :local_ledger_uuid])
    |> validate_inclusion(:status, @statuses)
  end

  defp fail_changeset(%Transaction{} = transaction, attrs) do
    transaction
    |> cast(attrs, [
      :status,
      :error_code,
      :error_description,
      :error_data
    ])
    |> validate_required([
      :status,
      :error_code
    ])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Gets all transactions for the given address.
  """
  def all_for_address(address) do
    from(t in Transaction, where: t.from == ^address or t.to == ^address)
  end

  def all_for_user(user) do
    from(t in Transaction, where: t.from_user_uuid == ^user.uuid or t.to_user_uuid == ^user.uuid)
  end

  def all_for_account_and_user_uuids(account_uuids, user_uuids) do
    from(
      t in Transaction,
      where:
        t.from_account_uuid in ^account_uuids or t.to_account_uuid in ^account_uuids or
          t.from_user_uuid in ^user_uuids or t.to_user_uuid in ^user_uuids
    )
  end

  def all_for_account(account) do
    from(
      t in Transaction,
      where: t.from_account_uuid == ^account.uuid or t.to_account_uuid == ^account.uuid
    )
  end

  @doc """
  Gets a transaction with the given idempotency token, inserts a new one if not found.
  """
  def get_or_insert(%{idempotency_token: idempotency_token} = attrs) do
    case get_by_idempotency_token(idempotency_token) do
      nil ->
        insert(attrs)

      transaction ->
        {:ok, transaction}
    end
  end

  @doc """
  Gets a transaction.
  """
  @spec get(String.t()) :: %Transaction{} | nil
  @spec get(String.t(), keyword()) :: %Transaction{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

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
      preload: [:from_wallet, :to_wallet, :from_token, :to_token]
    )
  end

  @doc """
  Inserts a transaction and ignores the conflicts on idempotency token, then retrieves the transaction
  using the passed idempotency token.
  """
  def insert(attrs) do
    opts = [on_conflict: :nothing, conflict_target: :idempotency_token]
    changeset = changeset(%Transaction{}, attrs)

    Multi.new()
    |> Multi.insert(:transaction, changeset, opts)
    |> Multi.run(:transaction_1, fn %{transaction: transaction} ->
      case get(transaction.id, preload: [:from_wallet, :to_wallet, :from_token, :to_token]) do
        nil ->
          {:ok, get_by_idempotency_token(transaction.idempotency_token)}

        transaction ->
          {:ok, transaction}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{transaction: _transaction, transaction_1: nil}} ->
        {:error, :inserted_transaction_could_not_be_loaded}

      {:ok, %{transaction: _transaction, transaction_1: transaction_1}} ->
        {:ok, transaction_1}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @doc """
  Confirms a transaction and saves the ledger's response.
  """
  def confirm(transaction, local_ledger_uuid) do
    transaction
    |> confirm_changeset(%{status: @confirmed, local_ledger_uuid: local_ledger_uuid})
    |> Repo.update()
    |> handle_update_result()
  end

  @doc """
  Sets a transaction as failed and saves the ledger's response.
  """
  def fail(transaction, error_code, error_description) when is_map(error_description) do
    do_fail(
      %{
        status: @failed,
        error_code: error_code,
        error_description: nil,
        error_data: error_description
      },
      transaction
    )
  end

  def fail(transaction, error_code, error_description) do
    do_fail(
      %{
        status: @failed,
        error_code: error_code,
        error_description: error_description,
        error_data: nil
      },
      transaction
    )
  end

  defp do_fail(%{error_code: error_code} = data, transaction) when is_atom(error_code) do
    data
    |> Map.put(:error_code, Atom.to_string(error_code))
    |> do_fail(transaction)
  end

  defp do_fail(data, transaction) do
    transaction
    |> fail_changeset(data)
    |> Repo.update()
    |> handle_update_result()
  end

  defp handle_update_result({:ok, transaction}) do
    Repo.preload(transaction, [:from_wallet, :to_wallet, :from_token, :to_token])
  end

  defp handle_update_result(error), do: error

  def get_error(nil), do: nil

  def get_error(transaction) do
    {transaction.error_code, transaction.error_description || transaction.error_data}
  end

  def failed?(transaction) do
    transaction.status == @failed
  end
end
