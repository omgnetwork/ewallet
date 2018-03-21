defmodule EWalletAPI.V1.TransactionRequestConsumptionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.TransactionRequestConsumptionView
  alias EWalletDB.TransactionRequestConsumption

  describe "EWalletAPI.V1.TransactionRequestConsumptionView.render/2" do
    test "renders transaction_request_consumption.json with correct structure" do
      request = insert(:transaction_request_consumption)
      consumption = TransactionRequestConsumption.get(request.id, preload: [:minted_token])

      result = render(TransactionRequestConsumptionView,
                      "transaction_request_consumption.json",
                      transaction_request_consumption: consumption)

      # The serializer tests should cover data transformation already, so we only test that
      # the view builds the expected object and wraps the data into the expected response format.
      assert %{
          version: _,
          success: _,
          data: %{
            object: "transaction_request_consumption",
          }
        } = result
    end
  end
end
