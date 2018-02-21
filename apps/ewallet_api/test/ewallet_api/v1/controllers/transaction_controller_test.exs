defmodule EWalletAPI.V1.TransactionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.User

  describe "/transactions.all" do

  end

  describe "/me.list_transactions" do
    test "returns idempotency error if header is not specified" do
      user = get_test_user()
      balance = User.get_primary_balance(user)

      insert(:transfer, %{from_balance: balance})
      insert(:transfer, %{from_balance: balance})
      insert(:transfer, %{to_balance:   balance})
      insert(:transfer, %{to_balance:   balance})
      insert(:transfer)
      insert(:transfer)

      response = client_request("/me.list_transactions", %{})

      assert response["data"]["data"] |> length() == 4
    end
  end
end
