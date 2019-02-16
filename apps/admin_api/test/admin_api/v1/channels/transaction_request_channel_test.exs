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

# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionRequestChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.TransactionRequestChannel
  alias EWalletDB.Account
  alias Ecto.UUID

  defp topic(id), do: "transaction_request:#{id}"

  describe "join/3" do
    test "can join the channel of a valid request" do
      request = insert(:transaction_request)
      topic = topic(request.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(TransactionRequestChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of an account's request that is a child of the current account" do
      master = Account.get_master_account()
      account = insert(:account, %{parent: master})
      request = insert(:transaction_request, %{account: account})
      topic = topic(request.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(TransactionRequestChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of an account's request that is a parrent account" do
      master_account = Account.get_master_account()
      account = insert(:account, %{parent: master_account})
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin)
      insert(:membership, %{user: admin, account: account, role: role})
      insert(:key, %{account: account, access_key: "a_sub_key", secret_key: "123"})
      request = insert(:transaction_request, %{account: master_account})
      topic = topic(request.id)

      test_with_auths(
        fn auth ->
          auth
          |> subscribe_and_join(TransactionRequestChannel, topic)
          |> assert_success(topic)
        end,
        admin.id,
        "a_sub_key"
      )
    end

    test "can't join the channel of an inexisting request" do
      topic = topic(UUID.generate())

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(TransactionRequestChannel, topic)
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
