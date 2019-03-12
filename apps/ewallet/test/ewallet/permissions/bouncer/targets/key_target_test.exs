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

defmodule EWallet.Bouncer.KeyTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{KeyTarget, DispatchConfig}
  alias Utils.Helpers.UUID

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the key" do
      key = insert(:key)
      res = KeyTarget.get_owner_uuids(key)
      assert res == [key.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert KeyTarget.get_target_types() == [:keys]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given key" do
      assert KeyTarget.get_target_type(Key) == :keys
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the key" do
      account_1 = insert(:account)
      account_2 = insert(:account)
      _ = insert(:account)
      key = insert(:key, accounts: [account_1, account_2])

      target_accounts_uuids =
        key |> KeyTarget.get_target_accounts(DispatchConfig) |> UUID.get_uuids()

      assert Enum.member?(target_accounts_uuids, account_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_2.uuid)
    end
  end
end
