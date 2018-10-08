defmodule EWalletAPI.V1.TransactionRequestViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.{TransactionRequestSerializer, TransactionRequestOverlay}
  alias EWalletAPI.V1.TransactionRequestView
  alias EWalletDB.TransactionRequest

  describe "EWalletAPI.V1.TransactionRequestView.render/2" do
    test "renders transaction_request.json with correct structure" do
      request = insert(:transaction_request)

      transaction_request =
        TransactionRequest.get(
          request.id,
          preload: TransactionRequestOverlay.default_preload_assocs()
        )

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
