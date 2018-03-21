defmodule EWallet.Web.V1.TransactionRequestSerializer do
  @moduledoc """
  Serializes transaction request data into V1 JSON response format.
  """
  alias EWallet.Web.V1.MintedTokenSerializer
  alias EWallet.Web.Date

  def serialize(transaction_request) do
    %{
      object: "transaction_request",
      id: transaction_request.id,
      socket_topic: "transaction_request:#{transaction_request.id}",
      type: transaction_request.type,
      minted_token: MintedTokenSerializer.serialize(transaction_request.minted_token),
      amount: transaction_request.amount,
      address: transaction_request.balance_address,
      user_id: transaction_request.user_id,
      account_id: transaction_request.account_id,
      correlation_id: transaction_request.correlation_id,
      status: transaction_request.status,
      confirmable: transaction_request.confirmable,
      max_consumptions: transaction_request.max_consumptions,
      consumption_lifetime: transaction_request.consumption_lifetime,
      expiration_date: transaction_request.expiration_date,
      expired_at: transaction_request.expired_at,
      expiration_reason: transaction_request.expiration_reason,
      allow_amount_override: transaction_request.allow_amount_override,
      metadata: transaction_request.metadata,
      encrypted_metadata: transaction_request.encrypted_metadata,
      created_at: Date.to_iso8601(transaction_request.inserted_at),
      updated_at: Date.to_iso8601(transaction_request.updated_at)
    }
  end
end
