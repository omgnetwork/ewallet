defmodule EWallet.Web.V1.TransactionRequestSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWalletDB.TransactionRequest
  alias EWallet.Web.V1.{TransactionRequestSerializer, MintedTokenSerializer}
  alias EWallet.Web.Date

  describe "serialize/1 for single transaction request" do
    test "serializes into correct V1 transaction_request format" do
      request = insert(:transaction_request)
      transaction_request = TransactionRequest.get(request.external_id, preload: [:minted_token,
                                                                                  :user,
                                                                                  :account])

      expected = %{
        object: "transaction_request",
        id: transaction_request.external_id,
        socket_topic: "transaction_request:#{transaction_request.external_id}",
        type: transaction_request.type,
        minted_token_id: transaction_request.minted_token.friendly_id,
        minted_token: MintedTokenSerializer.serialize(transaction_request.minted_token),
        amount: transaction_request.amount,
        user_id: transaction_request.user.external_id,
        account_id: get_in(transaction_request, [:account, :external_id]),
        address: transaction_request.balance_address,
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
        created_at: Date.to_iso8601(transaction_request.inserted_at),
        updated_at: Date.to_iso8601(transaction_request.updated_at)
      }

      assert TransactionRequestSerializer.serialize(transaction_request) == expected
    end
  end
end
