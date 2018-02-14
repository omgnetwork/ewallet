defmodule EWalletAPI.V1.TransactionRequestConsumptionSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletDB.TransactionRequestConsumption
  alias EWalletAPI.V1.JSON.TransactionRequestConsumptionSerializer

  describe "serialize/1 for single transaction request consumption" do
    test "serializes into correct V1 transaction_request consumption format" do
      request = insert(:transaction_request_consumption)
      consumption = TransactionRequestConsumption.get(request.id, preload: [:minted_token])

      expected = %{
        object: "transaction_request_consumption",
        id: consumption.id,
        status: consumption.status,
        amount: consumption.amount,
        token_id: consumption.minted_token.friendly_id,
        correlation_id: consumption.correlation_id,
        idempotency_token: consumption.idempotency_token,
        transfer_id: consumption.transfer_id,
        user_id: consumption.user_id,
        transaction_request_id: consumption.transaction_request_id,
        address: consumption.balance_address
      }

      assert TransactionRequestConsumptionSerializer.serialize(consumption) == expected
    end
  end
end
