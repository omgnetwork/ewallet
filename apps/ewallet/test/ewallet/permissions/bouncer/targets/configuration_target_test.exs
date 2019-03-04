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

defmodule EWallet.Bouncer.ConfigurationTargetTest do
  use EWallet.DBCase, async: true
  import EWalletConfig.Factory
  alias EWallet.Bouncer.{ConfigurationTarget, DispatchConfig}
  alias EWalletConfig.Setting

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the configuration" do
      stored_setting = insert(:stored_setting)
      setting = Setting.build(stored_setting)
      res = ConfigurationTarget.get_owner_uuids(setting)
      assert res == []
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert ConfigurationTarget.get_target_types() == [:configuration]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given configuration" do
      assert ConfigurationTarget.get_target_type(Setting) == :configuration
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the configuration" do
      stored_setting = insert(:stored_setting)
      setting = Setting.build(stored_setting)
      assert ConfigurationTarget.get_target_accounts(setting, DispatchConfig) == []
    end
  end
end
