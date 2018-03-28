defmodule EWallet.Web.V1.TransactionConsumptionConfirmationEventTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.Web.V1.TransactionConsumptionConfirmationEvent
  alias EWallet.TestEndpoint
  alias EWalletDB.Repo

  describe "broadcast/1" do
    test "broadcasts to the test endpoints" do
      {:ok, _} = TestEndpoint.start_link()

      consumption =
        :transaction_consumption
        |> insert()
        |> Repo.preload([:user, :transaction_request, :minted_token])

      res = TransactionConsumptionConfirmationEvent.broadcast(consumption)
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
        assert Enum.member?(mapped, {"transaction_consumption_confirmation", topic})
      end)

      :ok = TestEndpoint.stop()
    end
  end
end
