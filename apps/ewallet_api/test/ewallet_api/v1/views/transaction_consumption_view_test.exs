defmodule EWalletAPI.V1.TransactionConsumptionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.TransactionConsumptionView
  alias EWalletDB.TransactionConsumption

  describe "EWalletAPI.V1.TransactionConsumptionView.render/2" do
    test "renders transaction_consumption.json with correct structure" do
      request = insert(:transaction_consumption)
      consumption = TransactionConsumption.get(request.id, preload: [:minted_token])

      result =
        render(
          TransactionConsumptionView,
          "transaction_consumption.json",
          transaction_consumption: consumption
        )

      # The serializer tests should cover data transformation already, so we only test that
      # the view builds the expected object and wraps the data into the expected response format.
      assert %{
               version: _,
               success: _,
               data: %{
                 object: "transaction_consumption"
               }
             } = result
    end
  end
end
