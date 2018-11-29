# credo:disable-for-this-file
defmodule AdminAPI.V1.AccountChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.AccountChannel
  alias EWalletDB.Account

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

    test "joins the channel of an accessible account as an admin" do
      admin = get_test_admin()
      master = Account.get_master_account()

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, admin_user: admin}})
        |> subscribe_and_join(AccountChannel, "account:#{master.id}")

      assert res == :ok
      assert socket.topic == "account:#{master.id}"
    end

    test "can join a channel of an account that is a child of the current account" do
      master = Account.get_master_account()
      account = insert(:account, %{parent: master})

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: master}})
        |> subscribe_and_join(AccountChannel, "account:#{account.id}")

      assert res == :ok
      assert socket.topic == "account:#{account.id}"
    end

    test "can't join the channel of a parrent account as an admin" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin)
      insert(:membership, %{user: admin, account: account, role: role})
      master_account = Account.get_master_account()

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, admin_user: admin}})
        |> subscribe_and_join(AccountChannel, "account:#{master_account.id}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join a channel for an account that is a parent of the current account" do
      master = Account.get_master_account()
      account = insert(:account, %{parent: master})

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(AccountChannel, "account:#{master.id}")

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join a channel for an inexisting account" do
      account = insert(:account, %{id: "some_id"})

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(AccountChannel, "account:123")

      assert res == :error
      assert code == :forbidden_channel
    end
  end
end
