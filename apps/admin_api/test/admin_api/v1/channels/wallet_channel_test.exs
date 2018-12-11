# credo:disable-for-this-file
defmodule AdminAPI.V1.WalletChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.WalletChannel
  alias EWalletDB.{Account, AccountUser}

  defp topic(address), do: "address:#{address}"

  describe "join/3" do
    test "can join the channel of a current account's user's wallet" do
      user = insert(:user)
      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid)

      wallet = insert(:wallet, %{user: user})
      topic = topic(wallet.address)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(WalletChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of a child account's user's wallet" do
      user = insert(:user)
      master = Account.get_master_account()
      account = insert(:account, %{parent: master})
      {:ok, _} = AccountUser.link(account.uuid, user.uuid)

      wallet = insert(:wallet, %{user: user})
      topic = topic(wallet.address)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(WalletChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can't join the channel of a parent account's user's wallet" do
      user = insert(:user)
      master_account = Account.get_master_account()
      {:ok, _} = AccountUser.link(master_account.uuid, user.uuid)
      wallet = insert(:wallet, %{user: user})

      account = insert(:account, %{parent: master_account})
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin)
      insert(:membership, %{user: admin, account: account, role: role})
      insert(:key, %{account: account, access_key: "a_sub_key", secret_key: "123"})
      topic = topic(wallet.address)

      test_with_auths(
        fn auth ->
          auth
          |> subscribe_and_join(WalletChannel, topic)
          |> assert_failure(:forbidden_channel)
        end,
        admin.id,
        "a_sub_key"
      )
    end

    test "can join the channel of the current account's wallet" do
      wallet = Account.get_master_account() |> Account.get_primary_wallet()
      topic = topic(wallet.address)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(WalletChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of a child's account's wallet" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      topic = topic(wallet.address)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(WalletChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can't join the channel of a parent's account's wallet" do
      master_account = Account.get_master_account()
      wallet = Account.get_primary_wallet(master_account)

      account = insert(:account, %{parent: master_account})
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin)
      insert(:membership, %{user: admin, account: account, role: role})
      insert(:key, %{account: account, access_key: "a_sub_key", secret_key: "123"})
      topic = topic(wallet.address)

      test_with_auths(
        fn auth ->
          auth
          |> subscribe_and_join(WalletChannel, topic)
          |> assert_failure(:forbidden_channel)
        end,
        admin.id,
        "a_sub_key"
      )
    end

    test "can't join the channel of an inexisting wallet" do
      topic = topic("none000000000000")

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(WalletChannel, topic)
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
