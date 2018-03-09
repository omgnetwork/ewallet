defmodule EWalletAPI.V1.TransactionRequestViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletDB.TransactionRequest
  alias EWalletAPI.V1.TransactionRequestView
  alias EWallet.Web.{Date, V1.MintedTokenSerializer}

  describe "EWalletAPI.V1.TransactionRequestView.render/2" do
    test "renders transaction_request.json with correct structure" do
      request = insert(:transaction_request)
      transaction_request = TransactionRequest.get(request.id, preload: [:minted_token])

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "transaction_request",
          id: transaction_request.id,
          type: transaction_request.type,
          minted_token: MintedTokenSerializer.serialize(transaction_request.minted_token),
          amount: transaction_request.amount,
          address: transaction_request.balance_address,
          correlation_id: transaction_request.correlation_id,
          user_id: transaction_request.user_id,
          account_id: transaction_request.account_id,
          status: "valid",
          created_at: Date.to_iso8601(transaction_request.inserted_at),
          updated_at: Date.to_iso8601(transaction_request.updated_at)
        }
      }

      assert render(TransactionRequestView, "transaction_request.json",
                    transaction_request: transaction_request) == expected
    end
  end
end
