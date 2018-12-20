defmodule EWallet.ActivityLogGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.{ActivityLogGate}
  alias EWallet.Web.V1.Overlay
  alias EWalletDB.{User, Token}
  alias ActivityLogger.ActivityLog

  describe "add_originator_and_target/2" do
    test "inserts the originator and target structs in the list" do
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

      activity_logs = ActivityLogGate.add_originator_and_target(activity_logs, Overlay)

      assert Enum.at(activity_logs, 0).originator.uuid == user.uuid
      assert Enum.at(activity_logs, 0).target.uuid == token.uuid
      assert Enum.at(activity_logs, 1).originator.uuid == user.uuid
      assert Enum.at(activity_logs, 1).target == nil
    end
  end
end
