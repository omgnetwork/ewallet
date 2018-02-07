defmodule EWalletAPI.V1.TransactionRequestSerializerTest do
  use EWalletAPI.SerializerCase, :v1
  alias EWalletDB.TransactionRequest
  alias EWalletAPI.V1.JSON.TransactionRequestSerializer

  describe "serialize/1 for single transaction request" do
    test "serializes into correct V1 transaction_request format" do
      request = insert(:transaction_request)
      transaction_request = TransactionRequest.get(request.id, preload: [:minted_token])

      expected = %{
        object: "transaction_request",
        id: transaction_request.id,
        type: transaction_request.type,
        token_id: transaction_request.minted_token.friendly_id,
        amount: transaction_request.amount,
        balance_address: transaction_request.balance_address,
        correlation_id: transaction_request.correlation_id
      }

      assert TransactionRequestSerializer.serialize(transaction_request) == expected
    end
  end
end
