defmodule EWalletAPI.V1.TransactionRequestChannelTest do
  use EWalletAPI.ChannelCase
  alias EWalletAPI.V1.TransactionRequestChannel

  describe "join/3" do
    test "joins the channel" do
      {res, _, socket} =
        socket()
        |> subscribe_and_join(TransactionRequestChannel, "transaction_request:123")

      assert res == :ok
      assert socket.topic == "transaction_request:123"
    end
  end
end
