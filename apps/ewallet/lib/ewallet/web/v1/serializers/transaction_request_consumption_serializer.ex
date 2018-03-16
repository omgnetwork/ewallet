defmodule EWallet.Web.V1.TransactionRequestConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Date
  alias EWallet.Web.V1.{
    AccountSerializer,
    MintedTokenSerializer,
    TransactionSerializer,
    TransactionRequestSerializer
  }
  alias EWalletAPI.V1.UserSerializer
  alias EWalletDB.TransactionRequestConsumption

  def serialize(%TransactionRequestConsumption{} = consumption) do
    %{
      object: "transaction_request_consumption",
      id: consumption.id,
      status: consumption.status,
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
      created_at: Date.to_iso8601(consumption.inserted_at),
      updated_at: Date.to_iso8601(consumption.updated_at)
    }
  end
  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
