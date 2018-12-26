defmodule AdminAPI.V1.ActivityLogViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.ActivityLogView
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.{AccountSerializer, ActivityLogSerializer, UserSerializer}

  describe "AdminAPI.V1.ActivityLogView.render/2" do
    test "renders activity_log.json with correct response format" do
      activity_log = insert(:activity_log_preloaded)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "activity_log",
          id: activity_log.id,
          action: activity_log.action,
          originator_type: activity_log.originator_type,
          originator_identifier: activity_log.originator_identifier,
          originator: UserSerializer.serialize(activity_log.originator),
          target_type: activity_log.target_type,
          target_identifier: activity_log.target_identifier,
          target: AccountSerializer.serialize(activity_log.target),
          target_changes: activity_log.target_changes,
          target_encrypted_changes: activity_log.target_encrypted_changes,
          metadata: activity_log.metadata,
          created_at: Date.to_iso8601(activity_log.inserted_at)
        }
      }

      assert ActivityLogView.render("activity_log.json", %{activity_log: activity_log}) ==
               expected
    end

    test "renders activity_logs.json with correct response structure" do
      activity_log_1 = insert(:activity_log_preloaded)
      activity_log_2 = insert(:activity_log_preloaded)

      paginator = %Paginator{
        data: [activity_log_1, activity_log_2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: ActivityLogSerializer.serialize(paginator)
      }

      assert ActivityLogView.render("activity_logs.json", %{activity_logs: paginator}) == expected
    end
  end
end
