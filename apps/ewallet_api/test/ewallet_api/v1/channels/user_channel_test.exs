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
defmodule EWalletAPI.V1.UserChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.UserChannel

  defp topic(id), do: "user:#{id}"

  describe "join/3 as client" do
    test "joins the channel with authenticated user and same user (using id)" do
      user = get_test_user()

      user.id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_success(topic(user.id))
    end

    test "joins the channel with authenticated user and same user (using provider_user_id)" do
      user = get_test_user()

      user.provider_user_id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_success(topic(user.provider_user_id))
    end

    test "can't join channel with existing different user (using id)" do
      user = insert(:user)

      user.id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with existing different user (using provider_user_id)" do
      user = insert(:user)

      user.provider_user_id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with inexisting user" do
      "usr_123"
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_failure(:forbidden_channel)
    end
  end
end
