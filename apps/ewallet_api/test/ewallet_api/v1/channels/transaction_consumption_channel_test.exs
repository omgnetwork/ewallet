# credo:disable-for-this-file
defmodule EWalletAPI.V1.TransactionConsumptionChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.TransactionConsumptionChannel
  alias EWalletDB.User

  defp topic(id), do: "transaction_consumption:#{id}"

  describe "join/3 as client" do
    test "joins the channel with authenticated user and owned consumption" do
      user = get_test_user()
      wallet = User.get_primary_wallet(user)
      consumption = insert(:transaction_consumption, wallet_address: wallet.address)

      consumption.id
      |> topic()
      |> test_with_topic(TransactionConsumptionChannel)
      |> assert_success(topic(consumption.id))
    end

    test "can't join channel with existing not owned address" do
      consumption = insert(:transaction_consumption)

      consumption.id
      |> topic()
      |> test_with_topic(TransactionConsumptionChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with inexisting consumption" do
      "123"
      |> topic()
      |> test_with_topic(TransactionConsumptionChannel)
      |> assert_failure(:forbidden_channel)
    end
  end
end
