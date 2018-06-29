defmodule EWallet.Web.V1.TransactionConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}

  alias EWallet.Web.V1.{
    AccountSerializer,
    TokenSerializer,
    TransactionSerializer,
    TransactionRequestSerializer,
    UserSerializer,
    PaginatorSerializer
  }

  alias EWalletDB.TransactionConsumption
  alias EWalletDB.Helpers.{Assoc, Preloader}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%TransactionConsumption{} = consumption) do
    consumption =
      Preloader.preload(consumption, [
        :account,
        :token,
        :transaction_request,
        :transaction,
        :user
      ])

    %{
      object: "transaction_consumption",
      id: consumption.id,
      socket_topic: "transaction_consumption:#{consumption.id}",
      amount: consumption.amount,
      estimated_request_amount: consumption.estimated_request_amount,
      estimated_consumption_amount: consumption.estimated_consumption_amount,
      finalized_amount: TransactionConsumption.get_final_amount(consumption),
      token_id: consumption.token.id,
      token: TokenSerializer.serialize(consumption.token),
      correlation_id: consumption.correlation_id,
      idempotency_token: consumption.idempotency_token,
      transaction_id: Assoc.get(consumption, [:transaction, :id]),
      transaction: TransactionSerializer.serialize(consumption.transaction),
      user_id: Assoc.get(consumption, [:user, :id]),
      user: UserSerializer.serialize(consumption.user),
      account_id: Assoc.get(consumption, [:account, :id]),
      account: AccountSerializer.serialize(consumption.account),
      transaction_request_id: consumption.transaction_request.id,
      transaction_request:
        TransactionRequestSerializer.serialize(consumption.transaction_request),
      address: consumption.wallet_address,
      metadata: consumption.metadata || %{},
      encrypted_metadata: consumption.encrypted_metadata || %{},
      expiration_date: Date.to_iso8601(consumption.expiration_date),
      status: consumption.status,
      approved_at: Date.to_iso8601(consumption.approved_at),
      rejected_at: Date.to_iso8601(consumption.rejected_at),
      confirmed_at: Date.to_iso8601(consumption.confirmed_at),
      failed_at: Date.to_iso8601(consumption.failed_at),
      expired_at: Date.to_iso8601(consumption.expired_at),
      created_at: Date.to_iso8601(consumption.inserted_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
