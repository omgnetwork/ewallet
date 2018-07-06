defmodule AdminAPI.V1.TransactionCalculationView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, TransactionCalculationSerializer}

  def render("calculation.json", %{calculation: calculation}) do
    calculation
    |> TransactionCalculationSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
