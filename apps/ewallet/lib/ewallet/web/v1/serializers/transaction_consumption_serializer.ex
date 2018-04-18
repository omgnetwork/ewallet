defmodule EWallet.Web.V1.TransactionConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Date
  alias EWallet.Web.V1.{
    AccountSerializer,
    MintedTokenSerializer,
    TransactionSerializer,
    TransactionRequestSerializer,
    UserSerializer
  }
  alias EWalletDB.TransactionConsumption

  def serialize(%TransactionConsumption{} = consumption) do
    %{
      object: "transaction_consumption",
      id: consumption.id,
      socket_topic: "transaction_consumption:#{consumption.id}",
      amount: consumption.amount,
      minted_token_id: consumption.minted_token.friendly_id,
      minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
      correlation_id: consumption.correlation_id,
      idempotency_token: consumption.idempotency_token,
      transaction_id: consumption.transfer_id,
      transaction: TransactionSerializer.serialize(consumption.transfer),
      user_id: consumption.user_id,
      user: UserSerializer.serialize(consumption.user),
      account_id: consumption.account_id,
      account: AccountSerializer.serialize(consumption.account),
      transaction_request_id: consumption.transaction_request_id,
      transaction_request: TransactionRequestSerializer.serialize(consumption.transaction_request),
      address: consumption.balance_address,
      metadata: consumption.metadata,
      encrypted_metadata: consumption.encrypted_metadata,
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
