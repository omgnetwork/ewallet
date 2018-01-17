defmodule EWalletDB.Transfer do
  @moduledoc """
  Ecto Schema representing transfers.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.{Repo, Transfer, Balance, MintedToken}

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

  @primary_key {:id, UUID, autogenerate: true}

  schema "transfer" do
    field :idempotency_token, :string
    field :amount, EWalletDB.Types.Integer
    field :status, :string, default: @pending # pending -> confirmed
    field :type, :string, default: @internal # internal / external
    field :payload, Cloak.EncryptedMapField # Payload received from client
    field :ledger_response, Cloak.EncryptedMapField # Response returned by ledger
    field :metadata, Cloak.EncryptedMapField
    field :encryption_version, :binary
    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_id,
                                           references: :id,
                                           type: UUID
    belongs_to :to_balance, Balance, foreign_key: :to,
                                     references: :address,
                                     type: :string
    belongs_to :from_balance, Balance, foreign_key: :from,
                                       references: :address,
                                       type: :string
    timestamps()
  end

  defp changeset(%Transfer{} = transfer, attrs) do
    transfer
    |> cast(attrs, [
      :idempotency_token, :status, :type, :payload, :ledger_response, :metadata,
      :amount, :minted_token_id, :to, :from
    ])
    |> validate_required([
      :idempotency_token, :status, :type, :payload, :amount,
      :minted_token_id, :to, :from
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:type, @types)
    |> validate_immutable(:idempotency_token)
    |> unique_constraint(:idempotency_token)
    |> assoc_constraint(:minted_token)
    |> assoc_constraint(:to_balance)
    |> assoc_constraint(:from_balance)
    |> put_change(:encryption_version, Cloak.version)
  end

  @doc """
  Gets a transfer with the given idempotency token, inserts a new one if not found.
  """
  def get_or_insert(%{idempotency_token: idempotency_token} = attrs) do
    case get(idempotency_token, %{preload: true}) do
      nil ->
        insert(attrs)
      transfer ->
        {:ok, transfer}
    end
  end

  @doc """
  Gets a transfer with the given idempotency token.
  """
  def get(idempotency_token) do
    Transfer
    |> Repo.get_by(idempotency_token: idempotency_token)
  end

  @doc """
  Gets a transfer with the given idempotency token and preloads the from, to and minted token
  associations.
  """
  def get(idempotency_token, %{preload: true}) do
    idempotency_token
    |> get()
    |> Repo.preload([:from_balance, :to_balance, :minted_token])
  end

  @doc """
  Inserts a transfer and ignores the conflicts on idempotency token, then retrieves the transfer
  using the passed idempotency token.
  """
  def insert(attrs) do
    changeset = changeset(%Transfer{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :idempotency_token]
    case Repo.insert(changeset, opts) do
      {:ok, transfer} ->
        {:ok, get(transfer.idempotency_token, %{preload: true})}
      changeset ->
        changeset
    end
  end

  @doc """
  Confirms a transfer and saves the ledger's response.
  """
  def confirm(transfer, ledger_response) do
    transfer
    |> changeset(%{status: @confirmed, ledger_response: ledger_response})
    |> Repo.update()

    get(transfer.idempotency_token)
  end

  @doc """
  Sets a transfer as failed and saves the ledger's response.
  """
  def fail(transfer, ledger_response) do
    transfer
    |> changeset(%{status: @failed, ledger_response: ledger_response})
    |> Repo.update()

    get(transfer.idempotency_token)
  end
end
