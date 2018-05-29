defmodule EWalletDB.Transfer do
  @moduledoc """
  Ecto Schema representing transfers.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  alias Ecto.UUID
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

  schema "transfer" do
    external_id(prefix: "tfr_")

    field(:idempotency_token, :string)
    field(:amount, EWalletDB.Types.Integer)
    # pending -> confirmed
    field(:status, :string, default: @pending)
    # internal / external
    field(:type, :string, default: @internal)
    # Payload received from client
    field(:payload, Cloak.EncryptedMapField)
    # Response returned by ledger
    field(:ledger_response, Cloak.EncryptedMapField)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, Cloak.EncryptedMapField, default: %{})
    field(:encryption_version, :binary)

    belongs_to(
      :token,
      Token,
      foreign_key: :token_uuid,
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
      :ledger_response,
      :metadata,
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
    |> validate_immutable(:idempotency_token)
    |> unique_constraint(:idempotency_token)
    |> assoc_constraint(:token)
    |> assoc_constraint(:to_wallet)
    |> assoc_constraint(:from_wallet)
    |> put_change(:encryption_version, Cloak.version())
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

    %Transfer{}
    |> changeset(attrs)
    |> do_insert(opts)
    |> case do {_, res} -> res end
  end

  defp do_insert(changeset, opts) do
    Repo.transaction(fn ->
      case Repo.insert(changeset, opts) do
        {:ok, transfer} ->
          {:ok, get_by_idempotency_token(transfer.idempotency_token)}

        changeset ->
          changeset
      end
    end)
  end

  @doc """
  Confirms a transfer and saves the ledger's response.
  """
  def confirm(transfer, ledger_response) do
    transfer
    |> changeset(%{status: @confirmed, ledger_response: ledger_response})
    |> Repo.update()

    get_by_idempotency_token(transfer.idempotency_token)
  end

  @doc """
  Sets a transfer as failed and saves the ledger's response.
  """
  def fail(transfer, ledger_response) do
    transfer
    |> changeset(%{status: @failed, ledger_response: ledger_response})
    |> Repo.update()

    get_by_idempotency_token(transfer.idempotency_token)
  end

  def get_error(nil), do: nil

  def get_error(transfer) do
    {transfer.ledger_response["code"], transfer.ledger_response["description"]}
  end

  def failed?(transfer) do
    transfer.status == @failed
  end
end
