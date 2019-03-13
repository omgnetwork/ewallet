# Copyright 2018-2019 OmiseGO Pte Ltd
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

# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionConsumptionChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.TransactionConsumptionChannel
  alias EWalletDB.Account
  alias Ecto.UUID

  defp topic(id), do: "transaction_consumption:#{id}"

  describe "join/3" do
    test "can join the channel of a valid user's consumption" do
      consumption = insert(:transaction_consumption, %{account: nil})
      topic = topic(consumption.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(TransactionConsumptionChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of a valid account's consumption" do
      master = Account.get_master_account()
      consumption = insert(:transaction_consumption, %{account: master})
      topic = topic(consumption.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(TransactionConsumptionChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can't join the channel of an inexisting consumption" do
      topic = topic(UUID.generate())

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(TransactionConsumptionChannel, topic)
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
