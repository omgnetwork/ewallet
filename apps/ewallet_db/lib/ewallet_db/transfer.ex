defmodule EWalletDB.Transfer do
  @moduledoc """
  Ecto Schema representing transfers.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  alias Ecto.{UUID, Multi}
  import EWalletDB.Validator
  alias EWalletDB.{Repo, Transfer, Wallet, Token}

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
    external_id(prefix: "tfr_")

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
    field(:entry_uuid, :string)
    field(:error_code, :string)
    field(:error_description, :string)
    field(:error_data, :map)

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

    timestamps()
  end

  defp changeset(%Transfer{} = transfer, attrs) do
    transfer
    |> cast(attrs, [
      :idempotency_token,
      :status,
      :type,
      :payload,
      :metadata,
      :entry_uuid,
      :error_code,
      :error_description,
      :error_data,
      :encrypted_metadata,
      :amount,
      :token_uuid,
      :to,
      :from
    ])
    |> validate_required([
      :idempotency_token,
      :status,
      :type,
      :payload,
      :amount,
      :token_uuid,
      :to,
      :from,
      :metadata,
      :encrypted_metadata
    ])
    |> validate_from_wallet_identifier()
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:type, @types)
    |> validate_exclusive([:entry_uuid, :error_code])
    |> validate_immutable(:idempotency_token)
    |> unique_constraint(:idempotency_token)
    |> assoc_constraint(:token)
    |> assoc_constraint(:to_wallet)
    |> assoc_constraint(:from_wallet)
  end

  @doc """
  Gets all transfers for the given address.
  """
  def all_for_address(address) do
    from(t in Transfer, where: t.from == ^address or t.to == ^address)
  end

  @doc """
  Gets a transfer with the given idempotency token, inserts a new one if not found.
  """
  def get_or_insert(%{idempotency_token: idempotency_token} = attrs) do
    case get_by_idempotency_token(idempotency_token) do
      nil ->
        insert(attrs)

      transfer ->
        {:ok, transfer}
    end
  end

  @doc """
  Gets a transfer.
  """
  @spec get(ExternalID.t()) :: %Transfer{} | nil
  @spec get(ExternalID.t(), keyword()) :: %Transfer{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Get a transfer using one or more fields.
  """
  @spec get_by(keyword() | map(), keyword()) :: %Transfer{} | nil
  def get_by(map, opts \\ []) do
    query = Transfer |> Repo.get_by(map)

    case opts[:preload] do
      nil -> query
      preload -> Repo.preload(query, preload)
    end
  end

  @doc """
  Helper function to get a transfer with an idempotency token and loads all the required
  associations.
  """
  @spec get_by_idempotency_token(String.t()) :: %Transfer{} | nil
  def get_by_idempotency_token(idempotency_token) do
    get_by(
      %{
        idempotency_token: idempotency_token
      },
      preload: [:from_wallet, :to_wallet, :token]
    )
  end

  @doc """
  Inserts a transfer and ignores the conflicts on idempotency token, then retrieves the transfer
  using the passed idempotency token.
  """
  def insert(attrs) do
    opts = [on_conflict: :nothing, conflict_target: :idempotency_token]
    changeset = changeset(%Transfer{}, attrs)

    Multi.new()
    |> Multi.insert(:transfer, changeset, opts)
    |> Multi.run(:transfer_1, fn %{transfer: transfer} ->
      case get(transfer.id, preload: [:from_wallet, :to_wallet, :token]) do
        nil ->
          {:ok, get_by_idempotency_token(transfer.idempotency_token)}

        transfer ->
          {:ok, transfer}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{transfer: _transfer, transfer_1: nil}} ->
        {:error, :inserted_transaction_could_not_be_loaded}

      {:ok, %{transfer: _transfer, transfer_1: transfer_1}} ->
        {:ok, transfer_1}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @doc """
  Confirms a transfer and saves the ledger's response.
  """
  def confirm(transfer, entry_uuid) do
    transfer
    |> changeset(%{status: @confirmed, entry_uuid: entry_uuid})
    |> Repo.update()
    |> handle_update_result()
  end

  @doc """
  Sets a transfer as failed and saves the ledger's response.
  """
  def fail(transfer, error_code, error_description) when is_map(error_description) do
    do_fail(
      %{
        status: @failed,
        error_code: error_code,
        error_description: nil,
        error_data: error_description
      },
      transfer
    )
  end

  def fail(transfer, error_code, error_description) do
    do_fail(
      %{
        status: @failed,
        error_code: error_code,
        error_description: error_description,
        error_data: nil
      },
      transfer
    )
  end

  defp do_fail(%{error_code: error_code} = data, transfer) when is_atom(error_code) do
    data
    |> Map.put(:error_code, Atom.to_string(error_code))
    |> do_fail(transfer)
  end

  defp do_fail(data, transfer) do
    transfer
    |> changeset(data)
    |> Repo.update()
    |> handle_update_result()
  end

  defp handle_update_result({:ok, transfer}) do
    Repo.preload(transfer, [:from_wallet, :to_wallet, :token])
  end

  defp handle_update_result(error), do: error

  def get_error(nil), do: nil

  def get_error(transfer) do
    {transfer.error_code, transfer.error_description || transfer.error_data}
  end

  def failed?(transfer) do
    transfer.status == @failed
  end
end
