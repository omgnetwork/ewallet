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

defmodule EWallet.ActivityLogGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.{ActivityLogGate}
  alias EWallet.Web.V1.ModuleMapper
  alias EWalletDB.{User, Token}
  alias ActivityLogger.ActivityLog

  describe "load_originator_and_target/2" do
    test "loads the originator and target structs in the list" do
      user = insert(:user)
      token = insert(:token)

      activity_log1 =
        insert(
          :activity_log,
          %{
            originator_type: ActivityLog.get_type(User),
            originator_uuid: user.uuid,
            target_type: ActivityLog.get_type(Token),
            target_uuid: token.uuid
          }
        )

      activity_log2 =
        insert(:activity_log, %{
          originator_type: ActivityLog.get_type(User),
          originator_uuid: user.uuid
          # target is set to system in the factory
        })

      activity_logs = [activity_log1, activity_log2]

      assert_raise KeyError, fn -> activity_log1.originator end
      assert_raise KeyError, fn -> activity_log1.target end

      assert_raise KeyError, fn -> activity_log2.originator end
      assert_raise KeyError, fn -> activity_log2.target end

      activity_logs = ActivityLogGate.load_originator_and_target(activity_logs, ModuleMapper)

      assert Enum.at(activity_logs, 0).originator.uuid == user.uuid
      assert Enum.at(activity_logs, 0).target.uuid == token.uuid
      assert Enum.at(activity_logs, 1).originator.uuid == user.uuid
      assert Enum.at(activity_logs, 1).target == nil
    end
  end
end
