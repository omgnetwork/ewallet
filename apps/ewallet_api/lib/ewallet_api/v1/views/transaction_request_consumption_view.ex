defmodule EWalletAPI.V1.TransactionRequestConsumptionView do
  use EWalletAPI, :view
  use EWalletAPI.V1
  alias EWalletAPI.V1.{
    ResponseSerializer,
    TransactionRequestConsumptionSerializer
  }

  def render("transaction_request_consumption.json", %{
    transaction_request_consumption: consumption
  }) do
    consumption
    |> TransactionRequestConsumptionSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
