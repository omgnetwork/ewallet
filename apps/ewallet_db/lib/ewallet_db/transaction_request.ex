defmodule EWalletDB.TransactionRequest do
  @moduledoc """
  Ecto Schema representing transaction requests.
  """
  use Ecto.Schema
  import Ecto.Changeset
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

    field :confirmable, :boolean, default: false
    field :max_consumptions, :integer # nil -> unlimited
    field :consumption_lifetime, :integer
    field :expiration_date, :naive_datetime
    field :expired_at, :naive_datetime
    field :allow_amount_override, :boolean, default: false
    field :metadata, :map
    field :encrypted_metadata, Cloak.EncryptedMapField, default: %{}

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
      :minted_token_id, :balance_address, :confirmable, :max_consumptions,
      :consumption_lifetime, :expiration_date, :metadata, :encrypted_metadata,
      :allow_amount_override
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
    |> put_change(:encryption_version, Cloak.version)
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
        |> Repo.preload(opts[:preload])
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

  def expiration_from_lifetime(request) do
    lifetime? = request.consumption_lifetime && request.consumption_lifetime > 0

    case lifetime? do
      true  -> nil
      false -> nil
    end
  end
end
