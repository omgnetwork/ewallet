defmodule EWalletDB.TransactionRequest do
  @moduledoc """
  Ecto Schema representing transaction requests.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.{TransactionRequest, TransactionConsumption,
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
    field :consumption_lifetime, :integer # milliseconds
    field :expiration_date, :naive_datetime
    field :expired_at, :naive_datetime
    field :expiration_reason, :string
    field :allow_amount_override, :boolean, default: true
    field :metadata, :map, default: %{}
    field :encrypted_metadata, Cloak.EncryptedMapField, default: %{}

    has_many :consumptions, TransactionConsumption
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

  defp changeset(%TransactionRequest{} = transaction_request, attrs) do
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

  defp expire_changeset(%TransactionRequest{} = transaction_request, attrs) do
    transaction_request
    |> cast(attrs, [:status, :expired_at, :expiration_reason])
    |> validate_required([:status, :expired_at, :expiration_reason])
    |> validate_inclusion(:status, @statuses)
  end

  defp touch_changeset(%TransactionRequest{} = transaction_request, attrs) do
    transaction_request
    |> cast(attrs, [:updated_at])
    |> validate_required([:updated_at])
  end

  @doc """
  Gets a transaction request.
  """
  @spec get(UUID.t) :: %TransactionRequest{} | nil
  @spec get(UUID.t, List.t) :: %TransactionRequest{} | nil
  def get(nil), do: nil
  def get(id, opts \\ [preload: []])
  def get(nil, _), do: nil
  def get(id, nil), do: get(id, [preload: []])
  def get(id, opts) do
    case Helpers.UUID.valid?(id) do
      true ->
        TransactionRequest
        |> Repo.get(id)
        |> preload_option(opts)
      false -> nil
    end
  end

  def get_with_lock(id) do
    TransactionRequest
    |> where([t], t.id == ^id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  def touch(request) do
    request
    |> touch_changeset(%{updated_at: NaiveDateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Inserts a transaction request.
  """
  @spec insert(Map.t) :: {:ok, %TransactionRequest{}} | {:error, Map.t}
  def insert(attrs) do
    %TransactionRequest{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction request.
  """
  @spec insert(Map.t) :: {:ok, %TransactionRequest{}} | {:error, Map.t}
  def update(%TransactionRequest{} = request, attrs) do
    request
    |> changeset(attrs)
    |> Repo.update()
  end

  def expire(request, reason \\ "expired_request") do
    request
    |> expire_changeset(%{
      status: @expired,
      expired_at: NaiveDateTime.utc_now(),
      expiration_reason: reason
    })
    |> Repo.update()
  end

  def expire_if_max_consumption(request) do
    consumptions = TransactionConsumption.all_active_for_request(request.id)

    case max_consumptions_reached?(request, consumptions) do
      true  -> expire(request, "max_consumptions_reached")
      false -> touch(request)
    end
  end

  def max_consumptions_reached?(request, consumptions) do
    limited_consumptions?(request) &&
    length(consumptions) >= request.max_consumptions
  end

  def limited_consumptions?(request) do
    !is_nil(request.max_consumptions) && request.max_consumptions > 0
  end

  def valid?(request) do
    request.status == @valid
  end

  def expired?(request) do
    request.status == @expired
  end

  def expiration_from_lifetime(request) do
    lifetime? =
      request.confirmable &&
      request.consumption_lifetime &&
      request.consumption_lifetime > 0

    case lifetime? do
      true  ->
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(request.consumption_lifetime, :millisecond)
      _ -> nil
    end
  end
end
