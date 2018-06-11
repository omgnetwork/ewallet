defmodule EWallet.TransactionConsumptionSchedulerTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.Web.V1.WebsocketResponseSerializer
  alias EWallet.{TestEndpoint, TransactionConsumptionScheduler}
  alias EWalletDB.TransactionConsumption
  alias Phoenix.Socket.Broadcast

  setup do
    {:ok, pid} = TestEndpoint.start_link()
    
    on_exit fn ->
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end

    :ok
  end

  describe "expire_all/0" do
    test "expires all requests past their expiration date and send event" do
      now = NaiveDateTime.utc_now()

      # t1 and t2 have expiration dates in the past
      t1 =
        insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -60, :seconds))

      t2 =
        insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -600, :seconds))

      t3 =
        insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, 600, :seconds))

      t4 =
        insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, 160, :seconds))

      # They are still valid since we haven't made them expired yet
      assert TransactionConsumption.expired?(t1) == false
      assert TransactionConsumption.expired?(t2) == false
      assert TransactionConsumption.expired?(t3) == false
      assert TransactionConsumption.expired?(t4) == false

      TransactionConsumptionScheduler.expire_all()

      events = TestEndpoint.get_events()

      # 2 expired consumptions times 5 channels = 10 events
      assert length(events) == 10

      Enum.each(events, fn event ->
        {:socket_push, :text, encoded} =
          WebsocketResponseSerializer.fastlane!(%Broadcast{
            topic: event.topic,
            event: event.event,
            payload: event.payload
          })

        decoded = Poison.decode!(encoded)
        assert decoded["success"] == false
        assert decoded["event"] == "transaction_consumption_finalized"
        assert decoded["error"]["code"] == "transaction_consumption:expired"
        assert decoded["data"]["object"] == "transaction_consumption"
        assert decoded["data"]["status"] == "expired"
      end)

      # Reload all the records
      t1 = TransactionConsumption.get(t1.id)
      t2 = TransactionConsumption.get(t2.id)
      t3 = TransactionConsumption.get(t3.id)
      t4 = TransactionConsumption.get(t4.id)

      # Now t1 and t2 are expired
      assert TransactionConsumption.expired?(t1) == true
      assert TransactionConsumption.expired?(t2) == true
      assert TransactionConsumption.expired?(t3) == false
      assert TransactionConsumption.expired?(t4) == false
    end

    test "sets the expired_at field" do
      now = NaiveDateTime.utc_now()
      t = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -60, :seconds))
      TransactionConsumptionScheduler.expire_all()
      t = TransactionConsumption.get(t.id)

      assert TransactionConsumption.expired?(t) == true
      assert t.expired_at != nil
    end
  end
end
