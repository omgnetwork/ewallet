defmodule EWallet.Web.V1.TransactionConsumptionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWalletDB.Helpers.Assoc
  alias EWalletDB.TransactionConsumption
  alias EWallet.Web.Date

  alias EWallet.Web.V1.{
    AccountSerializer,
    TokenSerializer,
    TransactionConsumptionSerializer,
    TransactionRequestSerializer,
    TransactionSerializer,
    UserSerializer
  }

  describe "serialize/1 for single transaction request consumption" do
    test "serializes into correct V1 transaction_request consumption format" do
      consumption = insert(:transaction_consumption)

      consumption =
        TransactionConsumption.get(
          consumption.id,
          preload: [
            :token,
            :transaction,
            :transaction_request,
            :user,
            :exchange_wallet,
            :exchange_account
          ]
        )

      expected = %{
        object: "transaction_consumption",
        id: consumption.id,
        socket_topic: "transaction_consumption:#{consumption.id}",
        status: consumption.status,
        amount: consumption.amount,
        estimated_consumption_amount: nil,
        estimated_request_amount: nil,
        finalized_request_amount: nil,
        finalized_consumption_amount: nil,
        token_id: Assoc.get(consumption, [:token, :id]),
        token: TokenSerializer.serialize(consumption.token),
        correlation_id: consumption.correlation_id,
        idempotency_token: consumption.idempotency_token,
        transaction_id: Assoc.get(consumption, [:transaction, :id]),
        transaction: TransactionSerializer.serialize(consumption.transaction),
        user_id: Assoc.get(consumption, [:user, :id]),
        user: UserSerializer.serialize(consumption.user),
        account_id: nil,
        account: AccountSerializer.serialize(consumption.account),
        exchange_wallet: nil,
        exchange_wallet_address: nil,
        exchange_account: nil,
        exchange_account_id: nil,
        transaction_request_id: Assoc.get(consumption, [:transaction_request, :id]),
        transaction_request:
          TransactionRequestSerializer.serialize(consumption.transaction_request),
        address: consumption.wallet_address,
        metadata: %{},
        encrypted_metadata: %{},
        expiration_date: nil,
        approved_at: Date.to_iso8601(consumption.approved_at),
        rejected_at: Date.to_iso8601(consumption.rejected_at),
        confirmed_at: Date.to_iso8601(consumption.confirmed_at),
        failed_at: Date.to_iso8601(consumption.failed_at),
        expired_at: Date.to_iso8601(consumption.expired_at),
        created_at: Date.to_iso8601(consumption.inserted_at)
      }

      assert TransactionConsumptionSerializer.serialize(consumption) == expected
    end
  end
end
