defmodule AdminAPI.V1.ActivityLogViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.ActivityLogView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.ActivityLogSerializer

  describe "AdminAPI.V1.ActivityLogView.render/2" do
    test "renders activity_logs.json with correct response structure" do
      activity_log1 =
        :activity_log
        |> insert()
        |> Map.put(:originator, nil)
        |> Map.put(:target, nil)

      activity_log2 =
        :activity_log
        |> insert()
        |> Map.put(:originator, nil)
        |> Map.put(:target, nil)

      paginator = %Paginator{
        data: [activity_log1, activity_log2],
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
