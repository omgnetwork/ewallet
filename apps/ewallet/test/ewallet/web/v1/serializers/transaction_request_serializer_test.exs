defmodule EWallet.Web.V1.TransactionRequestSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWalletDB.Helpers.Assoc
  alias EWalletDB.TransactionRequest

  alias EWallet.Web.V1.{
    TransactionRequestOverlay,
    AccountSerializer,
    TokenSerializer,
    TransactionRequestSerializer,
    UserSerializer
  }

  alias EWallet.Web.Date

  describe "serialize/1 for single transaction request" do
    test "serializes into correct V1 transaction_request format" do
      request = insert(:transaction_request)

      transaction_request =
        TransactionRequest.get(request.id,
          preload: TransactionRequestOverlay.default_preload_assocs()
        )

      expected = %{
        object: "transaction_request",
        id: transaction_request.id,
        formatted_id: transaction_request.id,
        socket_topic: "transaction_request:#{transaction_request.id}",
        type: transaction_request.type,
        token_id: Assoc.get(transaction_request, [:token, :id]),
        token: TokenSerializer.serialize(transaction_request.token),
        amount: transaction_request.amount,
        user_id: Assoc.get(transaction_request, [:user, :id]),
        user: UserSerializer.serialize(transaction_request.user),
        account_id: Assoc.get(transaction_request, [:account, :id]),
        account: AccountSerializer.serialize(transaction_request.account),
        exchange_account: nil,
        exchange_account_id: nil,
        exchange_wallet: nil,
        exchange_wallet_address: nil,
        address: transaction_request.wallet_address,
        correlation_id: transaction_request.correlation_id,
        status: "valid",
        allow_amount_override: true,
        require_confirmation: false,
        consumption_lifetime: nil,
        metadata: %{},
        encrypted_metadata: %{},
        expiration_date: nil,
        expiration_reason: nil,
        expired_at: nil,
        max_consumptions: nil,
        max_consumptions_per_user: nil,
        current_consumptions_count: 0,
        created_at: Date.to_iso8601(transaction_request.inserted_at),
        updated_at: Date.to_iso8601(transaction_request.updated_at)
      }

      assert TransactionRequestSerializer.serialize(transaction_request) == expected
    end
  end
end
