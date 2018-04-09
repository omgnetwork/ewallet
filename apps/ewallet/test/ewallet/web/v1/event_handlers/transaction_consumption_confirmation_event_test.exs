defmodule EWallet.Web.V1.TransactionConsumptionEventHandlerTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.Web.V1.TransactionConsumptionEventHandler
  alias EWallet.TestEndpoint
  alias EWalletDB.Repo

  describe "broadcast/1" do
    test "broadcasts the 'transaction_consumption_finalized' event" do
      {:ok, _} = TestEndpoint.start_link()

      consumption =
        :transaction_consumption
        |> insert()
        |> Repo.preload([:user, :transaction_request, :minted_token])

      res = TransactionConsumptionEventHandler.broadcast(:transaction_consumption_finalized,
                                                         %{consumption: consumption})
      events = TestEndpoint.get_events()

      assert res == :ok
      assert length(events) == 5

      mapped = Enum.map(events, fn event -> {event.event, event.topic} end)
      [
        "transaction_request:#{consumption.transaction_request.id}",
        "address:#{consumption.balance_address}",
        "transaction_consumption:#{consumption.id}",
        "user:#{consumption.user_id}",
        "user:#{consumption.user.provider_user_id}"
      ]
      |> Enum.each(fn topic ->
        assert Enum.member?(mapped, {"transaction_consumption_finalized", topic})
      end)

      :ok = TestEndpoint.stop()
    end

    test "broadcasts the 'transaction_consumption_request' event" do
      {:ok, _} = TestEndpoint.start_link()

      consumption =
        :transaction_consumption
        |> insert()
        |> Repo.preload([:user, :transaction_request, :minted_token])

      res = TransactionConsumptionEventHandler.broadcast(:transaction_consumption_request,
                                                         %{consumption: consumption})
      events = TestEndpoint.get_events()

      assert res == :ok
      assert length(events) == 4

      request = consumption.transaction_request |> Repo.preload(:user)
      mapped = Enum.map(events, fn event -> {event.event, event.topic} end)
      [
        "transaction_request:#{request.id}",
        "address:#{request.balance_address}",
        "user:#{request.user.id}",
        "user:#{request.user.provider_user_id}"
      ]
      |> Enum.each(fn topic ->
        assert Enum.member?(mapped, {"transaction_consumption_request", topic})
      end)

      :ok = TestEndpoint.stop()
    end
  end
end
