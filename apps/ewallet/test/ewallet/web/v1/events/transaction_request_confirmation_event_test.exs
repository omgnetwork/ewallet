defmodule EWallet.Web.V1.TransactionConsumptionRequestEventTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.Web.V1.TransactionConsumptionRequestEvent
  alias EWallet.TestEndpoint
  alias EWalletDB.Repo

  describe "broadcast/1" do
    test "broadcasts to the test endpoints" do
      {:ok, _} = TestEndpoint.start_link()

      consumption =
        :transaction_consumption
        |> insert()
        |> Repo.preload([:user, :transaction_request, :minted_token])

      res = TransactionConsumptionRequestEvent.broadcast(consumption)
      events = TestEndpoint.get_events()

      assert res == :ok
      assert length(events) == 4

      mapped = Enum.map(events, fn event -> {event.event, event.topic} end)

      [
        "transaction_request:#{consumption.transaction_request.id}",
        "address:#{consumption.transaction_request.balance_address}",
        "user:#{consumption.transaction_request.user_id}",
        "user:#{consumption.user.provider_user_id}"

      ]
      |> Enum.each(fn topic ->
        assert Enum.member?(mapped, {"transaction_consumption_request", topic})
      end)

      :ok = TestEndpoint.stop()
    end
  end
end
