defmodule EWallet.Web.V1.EventTest do
  use EWallet.LocalLedgerCase, async: true
  import ExUnit.CaptureLog
  require Logger
  alias EWallet.Web.V1.Event
  alias EWallet.TestEndpoint

  setup do
    Logger.configure(level: :info)

    on_exit(fn ->
      Logger.configure(level: :warn)
    end)

    TestEndpoint.start_link()
    :ok
  end

  describe "log/3" do
    test "logs the event" do
      assert capture_log(fn ->
               Event.log("event", ["topic1"], %{"something" => "cool"})
             end) =~ "WEBSOCKET EVENT: Dispatching event 'event'"
    end

    test "logs a map error" do
      assert capture_log(fn ->
               Event.log("event", ["topic1"], %{
                 error: %{
                   code: "insufficient_funds",
                   description: %{
                     "address" => "b1c49cc8-7bed-4f18-a9b6-db696c012859",
                     "amount_to_debit" => 10_000_000,
                     "current_amount" => 0,
                     "token_id" => "tok_jon532_01CE0MF708E3B296FM4GFSXGRT"
                   }
                 }
               })
             end) =~ "WEBSOCKET EVENT: Dispatching event 'event'"
    end
  end
end
