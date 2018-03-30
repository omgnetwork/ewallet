defmodule EWalletAPI.V1.AddressChannelTest do
  use EWalletAPI.ChannelCase
  alias EWalletAPI.V1.AddressChannel

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid address" do
      balance = insert(:balance)
      account = insert(:account)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(AddressChannel, "address:#{balance.address}")

      assert res == :ok
      assert socket.topic == "address:#{balance.address}"
    end

    test "can't join a channel for an inexisting address" do
      account = insert(:account)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(AddressChannel, "address:123")

        assert res == :error
        assert code == :channel_not_found
    end
  end

  describe "join/3 as client" do
    test "joins the channel with authenticated user and owned address" do
      user = insert(:user)
      balance = insert(:balance, user: user)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(AddressChannel, "address:#{balance.address}")

      assert res == :ok
      assert socket.topic == "address:#{balance.address}"
    end

    test "can't join channel with existing not owned address" do
      user = insert(:user)
      balance = insert(:balance)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(AddressChannel, "address:#{balance.address}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join channel with inexisting address" do
      user = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(AddressChannel, "address:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
