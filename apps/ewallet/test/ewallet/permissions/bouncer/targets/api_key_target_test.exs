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

defmodule EWallet.Bouncer.APIKeyTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{APIKeyTarget, DispatchConfig}

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the api key" do
      user = insert(:user)
      api_key = insert(:api_key, creator_user: user)

      res = APIKeyTarget.get_owner_uuids(api_key)
      assert res == [user.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert APIKeyTarget.get_target_types() == [:api_keys]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given api key" do
      assert APIKeyTarget.get_target_type(ActivityLog) == :api_keys
    end
  end

  describe "get_target_accounts/2" do
    test "returns an empty list of account uuids" do
      api_key = insert(:api_key)
      assert APIKeyTarget.get_target_accounts(api_key, DispatchConfig) == []
    end
  end
end
