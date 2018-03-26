defmodule EWalletAPI.V1.UserChannelTest do
  use EWalletAPI.ChannelCase
  alias EWalletAPI.V1.UserChannel

  describe "join/3" do
    test "joins the channel" do
      {res, _, socket} =
        socket()
        |> subscribe_and_join(UserChannel, "user:123")

      assert res == :ok
      assert socket.topic == "user:123"
    end
  end
end
