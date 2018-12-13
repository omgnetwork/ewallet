# credo:disable-for-this-file
defmodule AdminAPI.V1.AccountChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.AccountChannel
  alias EWalletDB.Account
  alias Ecto.UUID

  defp topic(id), do: "account:#{id}"

  describe "join/3" do
    test "can join the channel of the current account" do
      master = Account.get_master_account()
      topic = topic(master.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(AccountChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of an account that is a child of the current account" do
      master = Account.get_master_account()
      account = insert(:account, %{parent: master})
      topic = topic(account.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(AccountChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can't join the channel of a parrent account" do
      master_account = Account.get_master_account()
      account = insert(:account, %{parent: master_account})
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin)
      insert(:membership, %{user: admin, account: account, role: role})
      insert(:key, %{account: account, access_key: "a_sub_key", secret_key: "123"})

      topic = topic(master_account.id)

      test_with_auths(
        fn auth ->
          auth
          |> subscribe_and_join(AccountChannel, topic)
          |> assert_failure(:forbidden_channel)
        end,
        admin.id,
        "a_sub_key"
      )
    end

    test "can't join the channel of an inexisting account" do
      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(AccountChannel, topic(UUID.generate()))
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
