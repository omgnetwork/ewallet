defmodule AdminAPI.V1.ActivityLogController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{ActivityLogPolicy, ActivityLogGate}
  alias EWallet.Web.{Orchestrator, Paginator, V1.ActivityLogOverlay, V1.Overlay}
  alias ActivityLogger.ActivityLog

  @doc """
  Retrieves a list of activity logs.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns),
         %Paginator{} = paginator <- Orchestrator.query(ActivityLog, ActivityLogOverlay, attrs),
         activity_logs <- ActivityLogGate.add_originator_and_target(paginator.data, Overlay),
         %Paginator{} = paginator <- Map.put(paginator, :data, activity_logs) do
      render(conn, :activity_logs, %{activity_logs: paginator})
    else
      {:error, code, description} ->
        handle_error(conn, code, description)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @spec permit(:all, map()) :: :ok | {:error, any()} | no_return()
  defp permit(action, params) do
    Bodyguard.permit(ActivityLogPolicy, action, params, nil)
  end
end
