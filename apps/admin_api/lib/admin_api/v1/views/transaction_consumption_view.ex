defmodule AdminAPI.V1.TransactionConsumptionView do
  use AdminAPI, :view

  alias EWallet.Web.V1.{
    ResponseSerializer,
    TransactionConsumptionSerializer
  }

  def render("transaction_consumption.json", %{
        transaction_consumption: consumption
      }) do
    consumption
    |> TransactionConsumptionSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("transaction_consumptions.json", %{
        transaction_consumptions: transaction_consumptions
      }) do
    transaction_consumptions
    |> TransactionConsumptionSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
