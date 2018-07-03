# credo:disable-for-this-file
defmodule EWalletAPI.V1.TransactionRequestChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.TransactionRequestChannel
  alias EWalletDB.User

  describe "join/3 as client" do
    test "joins the channel with authenticated user and owned request" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      request = insert(:transaction_request, wallet: wallet)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, user: user}})
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:#{request.id}")

      assert res == :ok
      assert socket.topic == "transaction_request:#{request.id}"
    end

    test "can't join channel with existing not owned address" do
      user = insert(:user)
      request = insert(:transaction_request)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, user: user}})
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:#{request.id}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join channel with inexisting request" do
      user = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, user: user}})
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
