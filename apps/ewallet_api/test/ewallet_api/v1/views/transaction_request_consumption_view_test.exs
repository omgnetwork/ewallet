defmodule EWalletAPI.V1.TransactionRequestConsumptionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletDB.TransactionRequestConsumption
  alias EWalletAPI.V1.TransactionRequestConsumptionView
  alias EWallet.Web.V1.TransactionRequestConsumptionSerializer

  describe "EWalletAPI.V1.TransactionRequestConsumptionView.render/2" do
    test "renders transaction_request_consumption.json with correct structure" do
      request = insert(:transaction_request_consumption)
      consumption = TransactionRequestConsumption.get(request.id, preload: [:minted_token])

      expected = %{
        version: @expected_version,
        success: true,
        data: TransactionRequestConsumptionSerializer.serialize(consumption)
      }

      assert render(TransactionRequestConsumptionView, "transaction_request_consumption.json",
                    transaction_request_consumption: consumption) == expected
    end
  end
end
