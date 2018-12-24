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

# credo:disable-for-this-file
defmodule AdminAPI.V1.UserChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.UserChannel
  alias EWalletDB.User
  alias Ecto.UUID

  defp topic(id), do: "user:#{id}"

  describe "join/3" do
    test "can join the channel of a valid user ID" do
      {:ok, user} = :user |> params_for() |> User.insert()

      topic = topic(user.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(UserChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of a valid provider user ID" do
      {:ok, user} = :user |> params_for() |> User.insert()
      topic = topic(user.provider_user_id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          UserChannel,
          topic
        )
        |> assert_success(topic)
      end)
    end

    test "can't join the channel of an inexisting user" do
      topic = topic(UUID.generate())

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(UserChannel, topic)
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
