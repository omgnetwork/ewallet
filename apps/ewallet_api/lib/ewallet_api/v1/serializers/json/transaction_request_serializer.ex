defmodule EWalletAPI.V1.JSON.TransactionRequestSerializer do
  @moduledoc """
  Serializes transaction request data into V1 JSON response format.
  """
  use EWalletAPI.V1

  def serialize(transaction_request) do
    %{
      object: "transaction_request",
      id: transaction_request.id,
      type: transaction_request.type,
      token_id: transaction_request.minted_token.friendly_id,
      amount: transaction_request.amount,
      balance_address: transaction_request.balance_address,
      correlation_id: transaction_request.correlation_id
    }
  end
end
