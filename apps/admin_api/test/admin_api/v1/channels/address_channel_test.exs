# credo:disable-for-this-file
defmodule AdminAPI.V1.WalletChannelTest do
  use AdminAPI.ChannelCase
  alias AdminAPI.V1.WalletChannel

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid address" do
      wallet = insert(:wallet)
      account = insert(:account)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(WalletChannel, "address:#{wallet.address}")

      assert res == :ok
      assert socket.topic == "address:#{wallet.address}"
    end

    test "can't join a channel for an inexisting address" do
      account = insert(:account)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(WalletChannel, "address:none000000000000")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
