defmodule KuberaDB.Transfer do
  @moduledoc """
  Ecto Schema representing transfers.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import KuberaDB.Validator
  alias Ecto.UUID
  alias KuberaDB.Repo
  alias KuberaDB.Transfer

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
    field :status, :string, default: @pending # pending -> confirmed
    field :type, :string, default: @internal # internal / external
    field :payload, Cloak.EncryptedMapField # Payload received from client
    field :ledger_response, Cloak.EncryptedMapField # Response returned by ledger
    field :metadata, Cloak.EncryptedMapField
    field :encryption_version, :binary

    timestamps()
  end

  defp changeset(%Transfer{} = transfer, attrs) do
    transfer
    |> cast(attrs, [
      :idempotency_token, :status, :type, :payload,
      :ledger_response, :metadata
    ])
    |> validate_required([
      :idempotency_token, :status, :type, :payload
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:type, @types)
    |> validate_immutable(:idempotency_token)
    |> unique_constraint(:idempotency_token)
    |> put_change(:encryption_version, Cloak.version)
  end

  def get_or_insert(%{
    idempotency_token: idempotency_token,
    type: type
  } = attrs) do
    case get(idempotency_token) do
      nil ->
        attrs
        |> Map.put(:type, type)
        |> insert()

        get(idempotency_token)
      transfer ->
        transfer
    end
  end

  def get(idempotency_token) do
    Repo.get_by(Transfer, idempotency_token: idempotency_token)
  end

  def insert(attrs) do
    changeset = changeset(%Transfer{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :idempotency_token]

    case Repo.insert(changeset, opts) do
      {:ok, transfer} ->
        {:ok, get(transfer.idempotency_token)}
      changeset ->
        changeset
    end
  end

  def confirm(transfer, ledger_response) do
    transfer
    |> changeset(%{status: @confirmed, ledger_response: ledger_response})
    |> Repo.update()

    get(transfer.idempotency_token)
  end

  def fail(transfer, ledger_response) do
    transfer
    |> changeset(%{status: @failed, ledger_response: ledger_response})
    |> Repo.update()

    get(transfer.idempotency_token)
  end
end
