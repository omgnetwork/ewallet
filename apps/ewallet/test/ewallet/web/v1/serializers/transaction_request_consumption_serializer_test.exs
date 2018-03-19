defmodule EWallet.Web.V1.TransactionRequestConsumptionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWalletDB.TransactionRequestConsumption
  alias EWallet.Web.V1.{TransactionRequestConsumptionSerializer, MintedTokenSerializer}
  alias EWallet.Web.Date

  describe "serialize/1 for single transaction request consumption" do
    test "serializes into correct V1 transaction_request consumption format" do
      request = insert(:transaction_request_consumption)
      consumption = TransactionRequestConsumption.get(request.id, preload: [:minted_token])

      expected = %{
        object: "transaction_request_consumption",
        id: consumption.id,
        socket_topic: "transaction_request_consumption:#{consumption.id}",
        status: consumption.status,
        amount: consumption.amount,
        minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
        correlation_id: consumption.correlation_id,
        idempotency_token: consumption.idempotency_token,
        transaction_id: nil,
        user_id: consumption.user_id,
        account_id: nil,
        transaction_request_id: consumption.transaction_request_id,
        address: consumption.balance_address,
        approved: false,
        finalized_at: nil,
        created_at: Date.to_iso8601(consumption.inserted_at),
        updated_at: Date.to_iso8601(consumption.updated_at)
      }

      assert TransactionRequestConsumptionSerializer.serialize(consumption) == expected
    end
  end
end
