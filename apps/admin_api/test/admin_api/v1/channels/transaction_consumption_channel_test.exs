# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionConsumptionChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.TransactionConsumptionChannel
  alias EWalletDB.Account
  alias Ecto.UUID

  defp topic(id), do: "transaction_consumption:#{id}"

  describe "join/3" do
    test "can join the channel of a valid user's consumption" do
      consumption = insert(:transaction_consumption, %{account: nil})

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          TransactionConsumptionChannel,
          topic(consumption.id)
        )
        |> assert_success(topic(consumption.id))
      end)
    end

    test "can join the channel of a valid account's consumption" do
      master = Account.get_master_account()
      consumption = insert(:transaction_consumption, %{account: master})

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          TransactionConsumptionChannel,
          topic(consumption.id)
        )
        |> assert_success(topic(consumption.id))
      end)
    end

    test "can join the channel of an account's consumption that is a child of the current account" do
      master = Account.get_master_account()
      account = insert(:account, %{parent: master})
      consumption = insert(:transaction_consumption, %{account: account})

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          TransactionConsumptionChannel,
          topic(consumption.id)
        )
        |> assert_success(topic(consumption.id))
      end)
    end

    test "can't join the channel of an account's consumption that is a parrent account" do
      master_account = Account.get_master_account()
      account = insert(:account, %{parent: master_account})
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin)
      insert(:membership, %{user: admin, account: account, role: role})
      insert(:key, %{account: account, access_key: "a_sub_key", secret_key: "123"})
      consumption = insert(:transaction_consumption, %{account: master_account})

      test_with_auths(
        fn auth ->
          auth
          |> subscribe_and_join(
            TransactionConsumptionChannel,
            topic(consumption.id)
          )
          |> assert_failure(:forbidden_channel)
        end,
        admin.id,
        "a_sub_key"
      )
    end

    test "can't join the channel of an inexisting consumption" do
      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          TransactionConsumptionChannel,
          topic(UUID.generate())
        )
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
