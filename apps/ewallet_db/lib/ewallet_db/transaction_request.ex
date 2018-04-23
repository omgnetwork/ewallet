defmodule EWalletDB.TransactionRequest do
  @moduledoc """
  Ecto Schema representing transaction requests.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Ecto.{UUID, Changeset}

  alias EWalletDB.{Account, Balance, MintedToken, TransactionRequest,
                   TransactionConsumption, Repo, User}

  @valid "valid"
  @expired "expired"
  @statuses [@valid, @expired]

  @send    "send"
  @receive "receive"
  @types   [@send, @receive]

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "transaction_request" do
    external_id prefix: "txr_"

    field :type, :string
    field :amount, EWalletDB.Types.Integer
    field :status, :string, default: @valid # valid -> expired
    field :correlation_id, :string

    field :require_confirmation, :boolean, default: false
    field :max_consumptions, :integer # nil -> unlimited
    field :consumption_lifetime, :integer # milliseconds
    field :expiration_date, :naive_datetime
    field :expired_at, :naive_datetime
    field :expiration_reason, :string
    field :allow_amount_override, :boolean, default: true
    field :metadata, :map, default: %{}
    field :encrypted_metadata, Cloak.EncryptedMapField, default: %{}

    has_many :consumptions, TransactionConsumption, foreign_key: :transaction_request_uuid,
                                                    references: :uuid

    belongs_to :user, User, foreign_key: :user_uuid,
                                         references: :uuid,
                                         type: UUID

    belongs_to :account, Account, foreign_key: :account_uuid,
                                  references: :uuid,
                                  type: UUID

    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_uuid,
                                           references: :uuid,
                                           type: UUID

    belongs_to :balance, Balance, foreign_key: :balance_address,
                                  references: :address,
                                  type: :string
    timestamps()
  end

  defp changeset(%TransactionRequest{} = transaction_request, attrs) do
    transaction_request
    |> cast(attrs, [
      :type, :amount, :correlation_id, :user_uuid, :account_uuid,
      :minted_token_uuid, :balance_address, :require_confirmation, :max_consumptions,
      :consumption_lifetime, :expiration_date, :metadata, :encrypted_metadata,
      :allow_amount_override
    ])
    |> validate_required([
      :type, :status, :minted_token_uuid, :balance_address
    ])
    |> validate_amount_if_disallow_override()
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

  defp validate_amount_if_disallow_override(changeset) do
    amount                = Changeset.get_field(changeset, :amount)
    allow_amount_override = Changeset.get_field(changeset, :allow_amount_override)

    validate_amount_if_disallow_override(changeset, allow_amount_override, amount)
  end
  defp validate_amount_if_disallow_override(changeset, false, nil) do
    Changeset.add_error(changeset,
                        :amount, "needs to be set if amount override is not allowed.")
  end
  defp validate_amount_if_disallow_override(changeset, _, _amount), do: changeset

  @doc """
  Gets a transaction request.
  """
  @spec get(ExternalID.t) :: %TransactionRequest{} | nil
  @spec get(ExternalID.t, keyword()) :: %TransactionRequest{} | nil
  def get(id, opts \\ [])
  def get(id, opts) when is_external_id(id) do
    TransactionRequest
    |> Repo.get_by(id: id)
    |> preload_option(opts)
  end
  def get(_id, _opts), do: nil

  @doc """
  Expires all transactions that are past their expiration_date.
  """
  @spec expire_all() :: {integer(), nil | [term()]} | no_return()
  def expire_all do
    now = NaiveDateTime.utc_now()

    TransactionRequest
    |> where([t], t.status == @valid)
    |> where([t], not is_nil(t.expiration_date))
    |> where([t], t.expiration_date <= ^now)
    |> Repo.update_all(set: [
      status: @expired,
      expired_at: NaiveDateTime.utc_now(),
      expiration_reason: "expired_transaction_request"
    ])
  end

  @doc """
  Gets a request with a "FOR UPDATE" lock on it. Should be called inside a transaction.
  """
  @spec get_with_lock(ExternalID.t()) :: %TransactionRequest{} | nil
  def get_with_lock(id) when is_external_id(id) do
    TransactionRequest
    |> where([t], t.id == ^id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end
  def get_with_lock(_), do: nil

  @doc """
  Touches a request by updating the `updated_at` field.
  """
  @spec touch(%TransactionRequest{}) :: {:ok, %TransactionRequest{}} |
                                                {:error, Map.t}
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

  @spec valid?(%TransactionRequest{}) :: true | false
  def valid?(request) do
    request.status == @valid
  end

  @spec expired?(%TransactionRequest{}) :: true | false
  def expired?(request) do
    request.status == @expired
  end

  @spec expiration_from_lifetime(%TransactionRequest{}) :: NaiveDateTime.t | nil
  def expiration_from_lifetime(request) do
    lifetime? =
      request.require_confirmation &&
      request.consumption_lifetime &&
      request.consumption_lifetime > 0

    case lifetime? do
      true  ->
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(request.consumption_lifetime, :millisecond)
      _ -> nil
    end
  end

  @doc """
  Expires the given request with the specified reason.
  """
  @spec expire(%TransactionRequest{}) :: {:ok, %TransactionRequest{}} | {:error, Map.t}
  def expire(request, reason \\ "expired_transaction_request") do
    request
    |> expire_changeset(%{
      status: @expired,
      expired_at: NaiveDateTime.utc_now(),
      expiration_reason: reason
    })
    |> Repo.update()
  end

  @doc """
  Expires the given request if the expiration date is past.
  """
  @spec expire_if_past_expiration_date(%TransactionRequest{}) ::
                                       {:ok, %TransactionRequest{}} | {:error, Map.t}
  def expire_if_past_expiration_date(request) do
    expired? = request.expiration_date &&
               NaiveDateTime.compare(request.expiration_date, NaiveDateTime.utc_now()) == :lt

    case expired? do
      true  -> expire(request)
      _     -> {:ok, request}
    end
  end

  @doc """
  Expires the given request if the maximum number of consumptions has been reached.
  """
  @spec expire_if_max_consumption(%TransactionRequest{}) :: {:ok, %TransactionRequest{}} |
                                                            {:error, Map.t}
  def expire_if_max_consumption(request) do
    consumptions = TransactionConsumption.all_active_for_request(request.uuid)

    case max_consumptions_reached?(request, consumptions) do
      true  -> expire(request, "max_consumptions_reached")
      false -> touch(request)
    end
  end

  @spec max_consumptions_reached?(%TransactionRequest{}, list(%TransactionConsumption{})) ::
    true | false
  defp max_consumptions_reached?(request, consumptions) do
    limited_consumptions?(request) &&
    length(consumptions) >= request.max_consumptions
  end

  @spec limited_consumptions?(%TransactionRequest{}) :: true | false
  defp limited_consumptions?(request) do
    !is_nil(request.max_consumptions) && request.max_consumptions > 0
  end
end
