defmodule EWalletAPI.V1.TransactionRequestConsumptionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletDB.TransactionRequestConsumption
  alias EWalletAPI.V1.TransactionRequestConsumptionView
  alias EWallet.Web.{Date, V1.MintedTokenSerializer}

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
          minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
          correlation_id: consumption.correlation_id,
          idempotency_token: consumption.idempotency_token,
          transaction_id: consumption.transfer_id,
          user_id: consumption.user_id,
          account_id: consumption.account_id,
          transaction_request_id: consumption.transaction_request_id,
          address: consumption.balance_address,
          created_at: Date.to_iso8601(consumption.inserted_at),
          updated_at: Date.to_iso8601(consumption.updated_at)
        }
      }

      assert render(TransactionRequestConsumptionView, "transaction_request_consumption.json",
                    transaction_request_consumption: consumption) == expected
    end
  end
end
