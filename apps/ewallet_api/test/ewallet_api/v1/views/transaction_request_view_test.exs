defmodule EWalletAPI.V1.TransactionRequestViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletDB.TransactionRequest
  alias EWalletAPI.V1.TransactionRequestView
  alias EWallet.Web.V1.TransactionRequestSerializer

  describe "EWalletAPI.V1.TransactionRequestView.render/2" do
    test "renders transaction_request.json with correct structure" do
      request = insert(:transaction_request)
      transaction_request = TransactionRequest.get(request.id, preload: [:token])

      expected = %{
        version: @expected_version,
        success: true,
        data: TransactionRequestSerializer.serialize(transaction_request)
      }

      assert render(
               TransactionRequestView,
               "transaction_request.json",
               transaction_request: transaction_request
             ) == expected
    end
  end
end
