defmodule EWalletAPI.V1.UserChannelTest do
  use EWalletAPI.ChannelCase
  alias EWalletAPI.V1.UserChannel
  alias EWalletDB.User

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid user ID" do
      account = insert(:account)
      user = insert(:user)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(UserChannel, "user:#{user.external_id}")

      assert res == :ok
      assert socket.topic == "user:#{user.external_id}"
    end

    test "joins the channel with authenticated account and valid provider user ID" do
      account = insert(:account)
      user = insert(:user)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(UserChannel, "user:#{user.provider_user_id}")

      assert res == :ok
      assert socket.topic == "user:#{user.provider_user_id}"
    end

    test "can't join a channel for an inexisting user" do
      account = insert(:account)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(UserChannel, "user:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end

  describe "join/3 as client" do
    test "joins the channel with authenticated user and same user (using id)" do
      {:ok, user} = :user |> params_for() |> User.insert()

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(UserChannel, "user:#{user.external_id}")

      assert res == :ok
      assert socket.topic == "user:#{user.external_id}"
    end

    test "joins the channel with authenticated user and same user (using provider_user_id)" do
      {:ok, user} = :user |> params_for() |> User.insert()

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(UserChannel, "user:#{user.provider_user_id}")

      assert res == :ok
      assert socket.topic == "user:#{user.provider_user_id}"
    end

    test "can't join channel with existing different user (using id)" do
      user1 = insert(:user)
      user2 = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user1}})
        |> subscribe_and_join(UserChannel, "user:#{user2.external_id}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join channel with existing different user (using provider_user_id)" do
      user1 = insert(:user)
      user2 = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user1}})
        |> subscribe_and_join(UserChannel, "user:#{user2.provider_user_id}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join channel with inexisting user" do
      user = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(UserChannel, "user:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
