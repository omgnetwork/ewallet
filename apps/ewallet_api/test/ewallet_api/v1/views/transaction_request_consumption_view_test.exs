defmodule EWalletAPI.V1.TransactionRequestConsumptionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletDB.TransactionRequestConsumption
  alias EWalletAPI.V1.TransactionRequestConsumptionView

  describe "EWalletAPI.V1.TransactionRequestConsumptionView.render/2" do
    test "renders transaction_request_consumption.json with correct structure" do
      request = insert(:transaction_request_consumption)
      consumption = TransactionRequestConsumption.get(request.id, preload: [:minted_token])

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "transaction_request_consumption",
          id: consumption.id,
          status: consumption.status,
          amount: consumption.amount,
          minted_token: %{
            object: "minted_token",
            id: consumption.minted_token.friendly_id,
            name: consumption.minted_token.name,
            subunit_to_unit: consumption.minted_token.subunit_to_unit,
            symbol: consumption.minted_token.symbol
          },
          correlation_id: consumption.correlation_id,
          idempotency_token: consumption.idempotency_token,
          transfer_id: consumption.transfer_id,
          user_id: consumption.user_id,
          transaction_request_id: consumption.transaction_request_id,
          address: consumption.balance_address
        }
      }

      assert render(TransactionRequestConsumptionView, "transaction_request_consumption.json",
                    transaction_request_consumption: consumption) == expected
    end
  end
end
