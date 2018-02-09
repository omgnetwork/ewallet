defmodule EWalletAPI.V1.JSON.TransactionRequestConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  use EWalletAPI.V1

  def serialize(consumption) do
    %{
      object: "transaction_request_consumption",
      id: consumption.id
    }
  end
end
