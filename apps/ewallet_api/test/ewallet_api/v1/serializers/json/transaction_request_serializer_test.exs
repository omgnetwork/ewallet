defmodule EWalletAPI.V1.TransactionRequestSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletDB.TransactionRequest
  alias EWalletAPI.V1.TransactionRequestSerializer
  alias EWallet.Web.Date

  describe "serialize/1 for single transaction request" do
    test "serializes into correct V1 transaction_request format" do
      request = insert(:transaction_request)
      transaction_request = TransactionRequest.get(request.id, preload: [:minted_token])

      expected = %{
        object: "transaction_request",
        id: transaction_request.id,
        type: transaction_request.type,
        minted_token: %{
          object: "minted_token",
          id: transaction_request.minted_token.friendly_id,
          name: transaction_request.minted_token.name,
          subunit_to_unit: transaction_request.minted_token.subunit_to_unit,
          symbol: transaction_request.minted_token.symbol,
          metadata: transaction_request.minted_token.metadata,
          encrypted_metadata: transaction_request.minted_token.encrypted_metadata
        },
        amount: transaction_request.amount,
        user_id: transaction_request.user_id,
        account_id: transaction_request.account_id,
        address: transaction_request.balance_address,
        correlation_id: transaction_request.correlation_id,
        status: "valid",
        created_at: Date.to_iso8601(transaction_request.inserted_at),
        updated_at: Date.to_iso8601(transaction_request.updated_at)
      }

      assert TransactionRequestSerializer.serialize(transaction_request) == expected
    end
  end
end
