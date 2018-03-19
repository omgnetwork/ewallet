defmodule EWalletDB.TransactionRequest do
  @moduledoc """
  Ecto Schema representing transaction requests.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import EWalletDB.Helpers.Preloader
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.{TransactionRequest, TransactionRequestConsumption,
                   Repo, MintedToken, User, Balance, Helpers}

  @valid "valid"
  @expired "expired"
  @statuses [@valid, @expired]

  @send    "send"
  @receive "receive"
  @types   [@send, @receive]

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "transaction_request" do
    field :type, :string
    field :amount, EWalletDB.Types.Integer
    field :status, :string, default: @valid # valid -> expired
    field :correlation_id, :string
    has_many :consumptions, TransactionRequestConsumption
    belongs_to :user, User, foreign_key: :user_id,
                                         references: :id,
                                         type: UUID
    belongs_to :account, Account, foreign_key: :account_id,
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

  defp create_changeset(%TransactionRequest{} = transaction_request, attrs) do
    transaction_request
    |> cast(attrs, [
      :type, :amount, :correlation_id, :user_id, :account_id,
      :minted_token_id, :balance_address
    ])
    |> validate_required([
      :type, :status, :minted_token_id, :balance_address
    ])
    |> validate_required_exclusive([:account_id, :user_id])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:correlation_id)
    |> assoc_constraint(:minted_token)
    |> assoc_constraint(:user)
    |> assoc_constraint(:balance)
    |> assoc_constraint(:account)
  end

  @doc """
  Gets a transaction request.
  """
  @spec get(UUID.t) :: %TransactionRequest{} | nil
  @spec get(UUID.t, List.t) :: %TransactionRequest{} | nil
  def get(nil), do: nil
  def get(id, opts \\ [preload: []])
  def get(nil, _), do: nil
  def get(id, opts) do
    case Helpers.UUID.valid?(id) do
      true ->
        TransactionRequest
        |> Repo.get(id)
        |> preload_option(opts)
      false -> nil
    end
  end

  @doc """
  Inserts a transaction request.
  """
  @spec insert(Map.t) :: {:ok, %TransactionRequest{}} | {:error, Map.t}
  def insert(attrs) do
    %TransactionRequest{}
    |> create_changeset(attrs)
    |> Repo.insert()
  end
end
