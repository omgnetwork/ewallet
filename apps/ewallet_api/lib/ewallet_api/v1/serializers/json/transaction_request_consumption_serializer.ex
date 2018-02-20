defmodule EWalletAPI.V1.JSON.TransactionRequestConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  use EWalletAPI.V1
  alias EWalletAPI.V1.JSON.MintedTokenSerializer

  def serialize(consumption) do
    %{
      object: "transaction_request_consumption",
      id: consumption.id,
      status: consumption.status,
      amount: consumption.amount,
      minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
      correlation_id: consumption.correlation_id,
      idempotency_token: consumption.idempotency_token,
      transfer_id: consumption.transfer_id,
      user_id: consumption.user_id,
      transaction_request_id: consumption.transaction_request_id,
      address: consumption.balance_address
    }
  end
end
