# credo:disable-for-this-file
defmodule AdminAPI.V1.AccountChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.AccountChannel

  describe "join/3 as provider" do
    test "joins the channel with authenticated account" do
      account = insert(:account)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(AccountChannel, "account:#{account.id}")

      assert res == :ok
      assert socket.topic == "account:#{account.id}"
    end

    test "can't join a channel for an inexisting account" do
      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true}})
        |> subscribe_and_join(AccountChannel, "account:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
