defmodule EWalletDB.TransactionConsumption do
  @moduledoc """
  Ecto Schema representing transaction request consumptions.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  alias Ecto.UUID
  alias LocalLedger.EctoBatchStream
  alias EWalletDB.{TransactionConsumption, Repo, User, MintedToken,
                   TransactionRequest, Balance, Helpers, Transfer, Account}

  @pending "pending"
  @confirmed "confirmed"
  @failed "failed"
  @expired "expired"
  @statuses [@pending, @confirmed, @failed, @expired]

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "transaction_request_consumption" do
    field :amount, EWalletDB.Types.Integer
    field :status, :string, default: @pending # pending -> confirmed
    field :correlation_id, :string
    field :idempotency_token, :string
    field :approved, :boolean, default: false
    field :finalized_at, :naive_datetime
    field :expired_at, :naive_datetime
    field :expiration_date, :naive_datetime
    field :metadata, :map, default: %{}
    field :encrypted_metadata, Cloak.EncryptedMapField, default: %{}
    belongs_to :transfer, Transfer, foreign_key: :transfer_id,
                                    references: :id,
                                    type: UUID
    belongs_to :user, User, foreign_key: :user_id,
                                         references: :id,
                                         type: UUID
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    belongs_to :transaction_request, TransactionRequest, foreign_key: :transaction_request_id,
                                     references: :id,
                                     type: UUID
    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_id,
                                           references: :id,
                                           type: UUID
    belongs_to :balance, Balance, foreign_key: :balance_address,
                                  references: :address,
                                  type: :string
    timestamps()
  end

  defp changeset(%TransactionConsumption{} = consumption, attrs) do
    consumption
    |> cast(attrs, [
      :amount, :idempotency_token, :correlation_id, :user_id, :account_id,
      :transaction_request_id, :balance_address, :minted_token_id,
      :metadata, :encrypted_metadata, :expiration_date
    ])
    |> validate_required([
      :status, :amount, :idempotency_token, :transaction_request_id,
      :balance_address, :minted_token_id
    ])
    |> validate_required_exclusive([:account_id, :user_id])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:idempotency_token)
    |> unique_constraint(:correlation_id)
    |> assoc_constraint(:user)
    |> assoc_constraint(:transaction_request)
    |> assoc_constraint(:balance)
    |> assoc_constraint(:account)
    |> put_change(:encryption_version, Cloak.version)
  end

  defp update_changeset(%TransactionConsumption{} = consumption, attrs) do
    consumption
    |> cast(attrs, [:status, :transfer_id])
    |> validate_required([:status, :transfer_id])
    |> assoc_constraint(:transfer)
  end

  defp approve_changeset(%TransactionConsumption{} = consumption, attrs) do
    consumption
    |> cast(attrs, [:approved, :finalized_at])
    |> validate_required([:approved, :finalized_at])
    |> assoc_constraint(:transfer)
  end

  def expire_all do
    now = NaiveDateTime.utc_now()

    TransactionConsumption
    |> where([t], t.status == @pending)
    |> where([t], not is_nil(t.expiration_date))
    |> where([t], t.expiration_date <= ^now)
    |> Repo.update_all(set: [
      status: @expired,
      expired_at: NaiveDateTime.utc_now()
    ])
  end

  @doc """
  Get all confirmed and pending transaction consumptions.
  """
  def all_active_for_request(request_id) do
    TransactionConsumption
    |> where([t], t.status in [@pending, @confirmed])
    |> where([t], t.transaction_request_id == ^request_id)
    |> Repo.all()
  end

  @doc """
  Gets a transaction request consumption.
  """
  @spec get(UUID.t) :: %TransactionConsumption{} | nil
  @spec get(UUID.t, List.t) :: %TransactionConsumption{} | nil
  def get(nil), do: nil
  def get(id, opts \\ [])
  def get(nil, _), do: nil
  def get(id, opts) do
    case Helpers.UUID.valid?(id) do
      true  -> get_by(%{id: id}, opts)
      false -> nil
    end
  end

  @doc """
  Get a consumption using one or more fields.
  """
  @spec get_by(Map.t, List.t) :: %TransactionConsumption{} | nil
  def get_by(map, opts \\ []) do
    query = TransactionConsumption |> Repo.get_by(map)

    case opts[:preload] do
      nil     -> query
      preload -> Repo.preload(query, preload)
    end
  end

  @doc """
  Inserts a transaction request consumption.
  """
  @spec insert(Map.t) :: {:ok, %TransactionConsumption{}} | {:error, Map.t}
  def insert(attrs) do
    changeset = changeset(%TransactionConsumption{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :idempotency_token]

    case Repo.insert(changeset, opts) do
      {:ok, consumption} ->
        {:ok, get_by(%{idempotency_token: consumption.idempotency_token})}
      error ->
        error
    end
  end

  @doc """
  Approves a consumption.
  """
  @spec approve(%TransactionConsumption{}) :: %TransactionConsumption{}
  def approve(consumption) do
    {:ok, consumption} =
      consumption
      |> approve_changeset(%{approved: true, finalized_at: NaiveDateTime.utc_now()})
      |> Repo.update()

    consumption
  end

  @doc """
  Rejects a consumption.
  """
  @spec reject(%TransactionConsumption{}) :: %TransactionConsumption{}
  def reject(consumption) do
    {:ok, consumption} =
      consumption
      |> approve_changeset(%{approved: false, finalized_at: NaiveDateTime.utc_now()})
      |> Repo.update()

    consumption
  end

  @doc """
  Confirms a consumption and saves the entry ID.
  """
  @spec confirm(%TransactionConsumption{}, %Transfer{}) :: %TransactionConsumption{}
  def confirm(consumption, transfer) do
    {:ok, consumption} =
      consumption
      |> update_changeset(%{
        status: @confirmed,
        transfer_id: transfer.id,
        confirmed_at: NaiveDateTime.utc_now()
      })
      |> Repo.update()

    consumption
  end

  @doc """
  Fails a consumption.
  """
  @spec fail(%TransactionConsumption{}, %Transfer{}) :: %TransactionConsumption{}
  def fail(consumption, transfer) do
    {:ok, consumption} =
      consumption
      |> update_changeset(%{status: @failed, transfer_id: transfer.id})
      |> Repo.update()

    consumption
  end
end
