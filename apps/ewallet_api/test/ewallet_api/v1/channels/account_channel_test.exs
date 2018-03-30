defmodule EWalletAPI.V1.AccountChannelTest do
  use EWalletAPI.ChannelCase
  alias EWalletAPI.V1.AccountChannel

  describe "join/3" do
    test "joins the channel with authenticated account" do
      account = insert(:account)

      {res, _, socket} =
        ""
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(AccountChannel, "account:123")

      assert res == :ok
      assert socket.topic == "account:123"
    end

    test "can't join channel with invalid auth" do
      {res, %{code: code}} =
        ""
        |> socket(%{auth: %{authenticated: :client, user: nil}})
        |> subscribe_and_join(AccountChannel, "account:123")

      assert res == :error
      assert code == :forbidden_channel
    end
  end
end
