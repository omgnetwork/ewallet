defmodule EWalletDB.TransactionRequestConsumption do
  @moduledoc """
  Ecto Schema representing transaction request consumptions.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{TransactionRequestConsumption, Repo, User, MintedToken,
                   TransactionRequest, Balance, Helpers, Transfer}

  @pending "pending"
  @confirmed "confirmed"
  @failed "failed"
  @statuses [@pending, @confirmed, @failed]

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "transaction_request_consumption" do
    field :amount, EWalletDB.Types.Integer
    field :status, :string, default: @pending # pending -> confirmed
    field :correlation_id, :string
    field :idempotency_token, :string
    belongs_to :transfer, Transfer, foreign_key: :transfer_id,
                                    references: :id,
                                    type: UUID
    belongs_to :user, User, foreign_key: :user_id,
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

  defp changeset(%TransactionRequestConsumption{} = consumption, attrs) do
    consumption
    |> cast(attrs, [
      :amount, :idempotency_token, :correlation_id, :user_id,
      :transaction_request_id, :balance_address, :minted_token_id
    ])
    |> validate_required([
      :status, :amount, :idempotency_token, :user_id, :transaction_request_id,
      :balance_address, :minted_token_id
    ])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:idempotency_token)
    |> unique_constraint(:correlation_id)
    |> assoc_constraint(:user)
    |> assoc_constraint(:transaction_request)
    |> assoc_constraint(:balance)
  end

  defp update_changeset(%TransactionRequestConsumption{} = consumption, attrs) do
    consumption
    |> cast(attrs, [:status, :transfer_id])
    |> validate_required([:status, :transfer_id])
    |> assoc_constraint(:transfer)
  end

  @doc """
  Gets a transaction request consumption.
  """
  def get(nil), do: nil
  def get(id, opts \\ [preload: []])
  def get(nil, _), do: nil
  def get(id, opts) do
    case Helpers.UUID.valid?(id) do
      true ->
        TransactionRequestConsumption
        |> Repo.get(id)
        |> Repo.preload(opts[:preload])
      false -> nil
    end
  end

  @doc """
  Inserts a transaction request consumption.
  """
  def insert(attrs) do
    %TransactionRequestConsumption{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Confirms a consumption and saves the entry ID.
  """
  def confirm(consumption, transfer) do
    {:ok, consumption} =
      consumption
      |> update_changeset(%{status: @confirmed, transfer_id: transfer.id})
      |> Repo.update()

    consumption
  end

  @doc """
  Fails a consumption.
  """
  def fail(consumption, transfer) do
    {:ok, consumption} =
      consumption
      |> update_changeset(%{status: @failed, transfer_id: transfer.id})
      |> Repo.update()

    consumption
  end
end
