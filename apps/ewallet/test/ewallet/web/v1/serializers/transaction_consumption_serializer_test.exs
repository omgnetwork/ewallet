defmodule EWallet.Web.V1.TransactionConsumptionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.{
    AccountSerializer,
    MintedTokenSerializer,
    TransactionSerializer,
    TransactionConsumptionSerializer,
    TransactionRequestSerializer,
    UserSerializer
  }
  alias EWallet.Web.Date
  alias EWalletDB.TransactionConsumption

  describe "serialize/1 for single transaction request consumption" do
    test "serializes into correct V1 transaction_request consumption format" do
      request = insert(:transaction_consumption)
      consumption = TransactionConsumption.get(request.external_id, preload: [:minted_token,
                                                                              :transfer,
                                                                              :user,
                                                                              :transaction_request])

      expected = %{
        object: "transaction_consumption",
        id: consumption.external_id,
        socket_topic: "transaction_consumption:#{consumption.external_id}",
        status: consumption.status,
        amount: consumption.amount,
        minted_token_id: consumption.minted_token.friendly_id,
        minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
        correlation_id: consumption.correlation_id,
        idempotency_token: consumption.idempotency_token,
        transaction_id: consumption[:transfer][:external_id],
        transaction: TransactionSerializer.serialize(consumption.transfer),
        user_id: consumption.user.external_id,
        user: UserSerializer.serialize(consumption.user),
        account_id: nil,
        account: AccountSerializer.serialize(consumption.account),
        transaction_request_id: consumption.transaction_request.external_id,
        transaction_request:
          TransactionRequestSerializer.serialize(consumption.transaction_request),
        address: consumption.balance_address,
        approved: false,
        metadata: %{},
        encrypted_metadata: %{},
        expiration_date: nil,
        expired_at: nil,
        finalized_at: nil,
        created_at: Date.to_iso8601(consumption.inserted_at),
        updated_at: Date.to_iso8601(consumption.updated_at)
      }

      assert TransactionConsumptionSerializer.serialize(consumption) == expected
    end
  end
end
