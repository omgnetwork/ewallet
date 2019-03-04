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

defmodule EWallet.Bouncer.CategoryTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{CategoryTarget, DispatchConfig}

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the category" do
      category = insert(:category)
      res = CategoryTarget.get_owner_uuids(category)
      assert res == []
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert CategoryTarget.get_target_types() == [:categories]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given category" do
      assert CategoryTarget.get_target_type(Category) == :categories
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the category" do
      account_1 = insert(:account)
      account_2 = insert(:account)
      _account = insert(:account)
      category = insert(:category, accounts: [account_1, account_2])

      target_accounts_uuids = category |> CategoryTarget.get_target_accounts(DispatchConfig) |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(target_accounts_uuids, account_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_2.uuid)
    end
  end
end
