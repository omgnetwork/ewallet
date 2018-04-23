defmodule EWalletAPI.V1.TransactionConsumptionChannelTest do
  use EWalletAPI.ChannelCase
  alias EWalletAPI.V1.TransactionConsumptionChannel
  alias EWalletDB.User

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid consumption" do
      account = insert(:account)
      consumption = insert(:transaction_consumption)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(
          TransactionConsumptionChannel,
          "transaction_consumption:#{consumption.id}"
        )

      assert res == :ok
      assert socket.topic == "transaction_consumption:#{consumption.id}"
    end

    test "can't join a channel for an inexisting consumption" do
      account = insert(:account)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :provider, account: account}})
        |> subscribe_and_join(TransactionConsumptionChannel, "transaction_consumption:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end

  describe "join/3 as client" do
    test "joins the channel with authenticated user and owned consumption" do
      {:ok, user} = :user |> params_for() |> User.insert()
      balance = User.get_primary_balance(user)
      consumption = insert(:transaction_consumption, balance_address: balance.address)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(
          TransactionConsumptionChannel,
          "transaction_consumption:#{consumption.id}"
        )

      assert res == :ok
      assert socket.topic == "transaction_consumption:#{consumption.id}"
    end

    test "can't join channel with existing not owned address" do
      user = insert(:user)
      consumption = insert(:transaction_consumption)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(
          TransactionConsumptionChannel,
          "transaction_consumption:#{consumption.id}"
        )

      assert res == :error
      assert code == :forbidden_channel
    end

    test "can't join channel with inexisting consumption" do
      user = insert(:user)

      {res, code} =
        "test"
        |> socket(%{auth: %{authenticated: :client, user: user}})
        |> subscribe_and_join(TransactionConsumptionChannel, "transaction_consumption:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
