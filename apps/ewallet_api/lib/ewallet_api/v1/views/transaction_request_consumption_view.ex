defmodule EWalletAPI.V1.TransactionRequestConsumptionView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{
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
