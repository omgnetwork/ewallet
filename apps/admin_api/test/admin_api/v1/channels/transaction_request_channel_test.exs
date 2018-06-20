# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionRequestChannelTest do
  use AdminAPI.ChannelCase
  alias AdminAPI.V1.TransactionRequestChannel

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid request" do
      account = insert(:account)
      request = insert(:transaction_request)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:#{request.id}")

      assert res == :ok
      assert socket.topic == "transaction_request:#{request.id}"
    end

    test "can't join a channel for an inexisting request" do
      account = insert(:account)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
