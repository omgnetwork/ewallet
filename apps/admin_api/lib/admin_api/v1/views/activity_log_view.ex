defmodule AdminAPI.V1.ActivityLogView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ActivityLogSerializer, ResponseSerializer}

  def render("activity_log.json", %{activity_log: activity_log}) do
    activity_log
    |> ActivityLogSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("activity_logs.json", %{activity_logs: activity_logs}) do
    activity_logs
    |> ActivityLogSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
