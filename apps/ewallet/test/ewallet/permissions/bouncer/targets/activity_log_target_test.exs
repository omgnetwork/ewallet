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

defmodule EWallet.Bouncer.ActivityLogTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{ActivityLogTarget, DispatchConfig}
  alias ActivityLogger.ActivityLog

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the activity log" do
      activity_log = insert(:activity_log)
      res = ActivityLogTarget.get_owner_uuids(activity_log)
      assert res == [activity_log.originator_uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert ActivityLogTarget.get_target_types() == [:activity_logs]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given account" do
      assert ActivityLogTarget.get_target_type(ActivityLog) == :activity_logs
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the current account" do
      activity_log = insert(:activity_log)
      assert ActivityLogTarget.get_target_accounts(activity_log, DispatchConfig) == []
    end
  end
end
