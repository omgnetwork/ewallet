defmodule EWallet.Web.V1.TransactionConsumptionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.UserSerializer
  alias EWalletDB.TransactionConsumption
  alias EWallet.Web.Date
  alias EWallet.Web.V1.{
    AccountSerializer,
    MintedTokenSerializer,
    TransactionSerializer,
    TransactionConsumptionSerializer,
    TransactionRequestSerializer
  }

  describe "serialize/1 for single transaction request consumption" do
    test "serializes into correct V1 transaction_request consumption format" do
      request = insert(:transaction_consumption)
      consumption = TransactionConsumption.get(request.id, preload: [:minted_token])

      expected = %{
        object: "transaction_consumption",
        id: consumption.id,
        socket_topic: "transaction_consumption:#{consumption.id}",
        status: consumption.status,
        amount: consumption.amount,
        minted_token_id: consumption.minted_token.friendly_id,
        minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
        correlation_id: consumption.correlation_id,
        idempotency_token: consumption.idempotency_token,
        transaction_id: consumption.transfer_id,
        transaction: TransactionSerializer.serialize(consumption.transfer),
        user_id: consumption.user_id,
        user: UserSerializer.serialize(consumption.user),
        account_id: nil,
        account: AccountSerializer.serialize(consumption.account),
        transaction_request_id: consumption.transaction_request_id,
        transaction_request:
          TransactionRequestSerializer.serialize(consumption.transaction_request),
        address: consumption.balance_address,
        metadata: %{},
        encrypted_metadata: %{},
        expiration_date: nil,
        approved_at: Date.to_iso8601(consumption.approved_at),
        rejected_at: Date.to_iso8601(consumption.rejected_at),
        confirmed_at: Date.to_iso8601(consumption.confirmed_at),
        failed_at: Date.to_iso8601(consumption.failed_at),
        expired_at: Date.to_iso8601(consumption.expired_at),
        created_at: Date.to_iso8601(consumption.inserted_at),
      }

      assert TransactionConsumptionSerializer.serialize(consumption) == expected
    end
  end
end
