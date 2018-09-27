# credo:disable-for-this-file
defmodule AdminAPI.V1.UserChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.UserChannel
  alias EWalletDB.User

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid user ID" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(UserChannel, "user:#{user.id}")

      assert res == :ok
      assert socket.topic == "user:#{user.id}"
    end

    test "joins the channel with authenticated account and valid provider user ID" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(UserChannel, "user:#{user.provider_user_id}")

      assert res == :ok
      assert socket.topic == "user:#{user.provider_user_id}"
    end

    test "can't join a channel for an inexisting user" do
      account = insert(:account)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(UserChannel, "user:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
