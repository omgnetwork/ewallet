# credo:disable-for-this-file
defmodule EWalletAPI.V1.WalletChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.WalletChannel

  describe "join/3 as client" do
    test "joins the channel with authenticated user and owned address" do
      user = insert(:user)
      wallet = insert(:wallet, user: user)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, user: user}})
        |> subscribe_and_join(WalletChannel, "address:#{wallet.address}")

      assert res == :ok
      assert socket.topic == "address:#{wallet.address}"
    end

    test "can't join channel with existing not owned address" do
      user = insert(:user)
      wallet = insert(:wallet)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, user: user}})
        |> subscribe_and_join(WalletChannel, "address:#{wallet.address}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join channel with inexisting address" do
      user = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, user: user}})
        |> subscribe_and_join(WalletChannel, "address:none000000000000")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
