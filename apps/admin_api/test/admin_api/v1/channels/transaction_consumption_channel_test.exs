# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionConsumptionChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.TransactionConsumptionChannel

  describe "join/3 as provider" do
    test "joins the channel with authenticated account and valid consumption" do
      account = insert(:account)
      consumption = insert(:transaction_consumption)

      {res, _, socket} =
        "test"
        |> socket(%{auth: %{authenticated: true, account: account}})
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
        |> socket(%{auth: %{authenticated: true, account: account}})
        |> subscribe_and_join(TransactionConsumptionChannel, "transaction_consumption:123")

      assert res == :error
      assert code == :channel_not_found
    end
  end
end
