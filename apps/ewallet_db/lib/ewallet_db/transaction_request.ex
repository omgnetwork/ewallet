defmodule EWalletDB.TransactionRequest do
  @moduledoc """
  Ecto Schema representing transaction requests.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Ecto.{UUID, Changeset, Query}

  alias EWalletDB.{
    Account,
    Wallet,
    Token,
    TransactionRequest,
    TransactionConsumption,
    Repo,
    User
  }

  @valid "valid"
  @expired "expired"
  @statuses [@valid, @expired]

  @send "send"
  @receive "receive"
  @types [@send, @receive]

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "transaction_request" do
    external_id(prefix: "txr_")

    field(:type, :string)
    field(:amount, EWalletDB.Types.Integer)
    # valid -> expired
    field(:status, :string, default: @valid)
    field(:correlation_id, :string)

    field(:require_confirmation, :boolean, default: false)
    # nil -> unlimited
    field(:max_consumptions, :integer)
    field(:max_consumptions_per_user, :integer)
    # milliseconds
    field(:consumption_lifetime, :integer)
    field(:expiration_date, :naive_datetime)
    field(:expired_at, :naive_datetime)
    field(:expiration_reason, :string)
    field(:allow_amount_override, :boolean, default: true)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, EWalletDB.Encrypted.Map, default: %{})

    has_many(
      :consumptions,
      TransactionConsumption,
      foreign_key: :transaction_request_uuid,
      references: :uuid
    )

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :token,
      Token,
      foreign_key: :token_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :wallet,
      Wallet,
      foreign_key: :wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :exchange_account,
      Account,
      foreign_key: :exchange_account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :exchange_wallet,
      Wallet,
      foreign_key: :exchange_wallet_address,
      references: :address,
      type: :string
    )

    timestamps()
  end

  defp changeset(%TransactionRequest{} = transaction_request, attrs) do
    transaction_request
    |> cast(attrs, [
      :type,
      :amount,
      :correlation_id,
      :user_uuid,
      :account_uuid,
      :token_uuid,
      :wallet_address,
      :require_confirmation,
      :max_consumptions,
      :max_consumptions_per_user,
      :consumption_lifetime,
      :expiration_date,
      :metadata,
      :encrypted_metadata,
      :allow_amount_override,
      :exchange_account_uuid,
      :exchange_wallet_address
    ])
    |> validate_required([
      :type,
      :status,
      :token_uuid,
      :wallet_address
    ])
    |> validate_amount_if_disallow_override()
    |> validate_number(:amount, less_than: 100_000_000_000_000_000_000_000_000_000_000_000)
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:correlation_id)
    |> assoc_constraint(:token)
    |> assoc_constraint(:user)
    |> assoc_constraint(:wallet)
    |> assoc_constraint(:exchange_account)
    |> assoc_constraint(:exchange_wallet)
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
    amount = Changeset.get_field(changeset, :amount)
    allow_amount_override = Changeset.get_field(changeset, :allow_amount_override)

    validate_amount_if_disallow_override(changeset, allow_amount_override, amount)
  end

  defp validate_amount_if_disallow_override(changeset, false, nil) do
    Changeset.add_error(changeset, :amount, "needs to be set if amount override is not allowed.")
  end

  defp validate_amount_if_disallow_override(changeset, _, _amount), do: changeset

  @doc """
  Gets a transaction request.
  """
  @spec get(ExternalID.t()) :: %TransactionRequest{} | nil
  @spec get(ExternalID.t(), keyword()) :: %TransactionRequest{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    TransactionRequest
    |> Repo.get_by(id: id)
    |> preload_option(opts)
  end

  def get(_id, _opts), do: nil

  def query_all_for_account_and_user_uuids(account_uuids, user_uuids) do
    from(
      t in TransactionRequest,
      where: t.account_uuid in ^account_uuids or t.user_uuid in ^user_uuids
    )
  end

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
    |> Repo.update_all(
      set: [
        status: @expired,
        expired_at: NaiveDateTime.utc_now(),
        expiration_reason: "expired_transaction_request"
      ]
    )
  end

  @doc """
  Gets a request with a "FOR UPDATE" lock on it. Should be called inside a transaction.
  """
  @spec get_with_lock(ExternalID.t()) :: %TransactionRequest{} | nil
  def get_with_lock(id, preloads \\ [])

  def get_with_lock(id, preloads) when is_external_id(id) do
    TransactionRequest
    |> where([t], t.id == ^id)
    |> lock("FOR UPDATE")
    |> Query.preload(^preloads)
    |> Repo.one()
  end

  def get_with_lock(_, _), do: nil

  @doc """
  Touches a request by updating the `updated_at` field.
  """
  @spec touch(%TransactionRequest{}) ::
          {:ok, %TransactionRequest{}}
          | {:error, Map.t()}
  def touch(request) do
    request
    |> touch_changeset(%{updated_at: NaiveDateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Inserts a transaction request.
  """
  @spec insert(Map.t()) :: {:ok, %TransactionRequest{}} | {:error, Map.t()}
  def insert(attrs) do
    %TransactionRequest{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction request.
  """
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

  @spec expiration_from_lifetime(%TransactionRequest{}) :: NaiveDateTime.t() | nil
  def expiration_from_lifetime(request) do
    lifetime? =
      request.require_confirmation && request.consumption_lifetime &&
        request.consumption_lifetime > 0

    case lifetime? do
      true ->
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(request.consumption_lifetime, :millisecond)

      _ ->
        nil
    end
  end

  @doc """
  Expires the given request with the specified reason.
  """
  @spec expire(%TransactionRequest{}) :: {:ok, %TransactionRequest{}} | {:error, Map.t()}
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
          {:ok, %TransactionRequest{}} | {:error, Map.t()}
  def expire_if_past_expiration_date(request) do
    expired? =
      request.expiration_date &&
        NaiveDateTime.compare(request.expiration_date, NaiveDateTime.utc_now()) == :lt

    case expired? do
      true -> expire(request)
      _ -> {:ok, request}
    end
  end

  @doc """
  Expires the given request if the maximum number of consumptions has been reached.
  """
  @spec expire_if_max_consumption(%TransactionRequest{}) ::
          {:ok, %TransactionRequest{}}
          | {:error, Map.t()}
  def expire_if_max_consumption(request) do
    consumptions = TransactionConsumption.all_active_for_request(request.uuid)

    case max_consumptions_reached?(request, consumptions) do
      true -> expire(request, "max_consumptions_reached")
      false -> touch(request)
    end
  end

  @spec max_consumptions_reached?(%TransactionRequest{}, list(%TransactionConsumption{})) ::
          true | false
  defp max_consumptions_reached?(request, consumptions) do
    limited_consumptions?(request) && length(consumptions) >= request.max_consumptions
  end

  @spec limited_consumptions?(%TransactionRequest{}) :: true | false
  defp limited_consumptions?(request) do
    !is_nil(request.max_consumptions) && request.max_consumptions > 0
  end
end
