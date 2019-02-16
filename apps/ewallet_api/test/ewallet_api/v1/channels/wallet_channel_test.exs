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
defmodule EWalletAPI.V1.WalletChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.WalletChannel
  alias EWalletDB.User

  defp topic(address), do: "address:#{address}"

  describe "join/3 as client" do
    test "Can join the channel with authenticated user and owned address" do
      wallet = User.get_primary_wallet(get_test_user())

      wallet.address
      |> topic()
      |> test_with_topic(WalletChannel)
      |> assert_success(topic(wallet.address))
    end

    test "can't join channel with existing not owned address" do
      wallet = insert(:wallet)

      wallet.address
      |> topic()
      |> test_with_topic(WalletChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with inexisting address" do
      "none000000000000"
      |> topic()
      |> test_with_topic(WalletChannel)
      |> assert_failure(:forbidden_channel)
    end
  end
end
