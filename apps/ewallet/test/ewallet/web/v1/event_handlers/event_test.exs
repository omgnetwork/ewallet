# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.Web.V1.EventTest do
  use EWallet.DBCase, async: true
  import ExUnit.CaptureLog
  require Logger
  alias EWallet.TestEndpoint
  alias EWallet.Web.V1.Event

  setup do
    Logger.configure(level: :info)
    {:ok, pid} = TestEndpoint.start_link()

    on_exit(fn ->
      Logger.configure(level: :warn)
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end)

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
