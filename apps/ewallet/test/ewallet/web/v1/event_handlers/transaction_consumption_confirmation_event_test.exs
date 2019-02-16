# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.TransactionConsumptionEventHandlerTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.TestEndpoint
  alias EWallet.Web.V1.TransactionConsumptionEventHandler
  alias EWalletDB.Repo

  setup do
    {:ok, pid} = TestEndpoint.start_link()

    on_exit(fn ->
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end)

    :ok
  end

  describe "broadcast/1" do
    test "broadcasts the 'transaction_consumption_finalized' event" do
      consumption =
        :transaction_consumption
        |> insert()
        |> Repo.preload([:user, :transaction_request, :token])

      request = consumption |> Repo.preload([:user])

      res =
        TransactionConsumptionEventHandler.broadcast(:transaction_consumption_finalized, %{
          consumption: consumption
        })

      events = TestEndpoint.get_events()

      assert res == :ok
      assert length(events) == 8

      mapped = Enum.map(events, fn event -> {event.event, event.topic} end)

      [
        "transaction_request:#{consumption.transaction_request.id}",
        "address:#{consumption.wallet_address}",
        "address:#{request.wallet_address}",
        "transaction_consumption:#{consumption.id}",
        "user:#{consumption.user.id}",
        "user:#{consumption.user.provider_user_id}",
        "user:#{request.user.id}",
        "user:#{request.user.provider_user_id}"
      ]
      |> Enum.each(fn topic ->
        assert Enum.member?(mapped, {"transaction_consumption_finalized", topic})
      end)
    end

    test "broadcasts the 'transaction_consumption_request' event" do
      consumption =
        :transaction_consumption
        |> insert()
        |> Repo.preload([:user, :transaction_request, :token])

      res =
        TransactionConsumptionEventHandler.broadcast(:transaction_consumption_request, %{
          consumption: consumption
        })

      events = TestEndpoint.get_events()

      assert res == :ok
      assert length(events) == 4

      request = consumption.transaction_request |> Repo.preload(:user)
      mapped = Enum.map(events, fn event -> {event.event, event.topic} end)

      [
        "transaction_request:#{request.id}",
        "address:#{request.wallet_address}",
        "user:#{request.user.id}",
        "user:#{request.user.provider_user_id}"
      ]
      |> Enum.each(fn topic ->
        assert Enum.member?(mapped, {"transaction_consumption_request", topic})
      end)
    end
  end
end
