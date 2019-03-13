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

defmodule AdminAPI.V1.ActivityLogController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{ActivityLogPolicy, ActivityLogGate}
  alias EWallet.Web.{Orchestrator, Paginator, V1.ActivityLogOverlay, V1.ModuleMapper}

  @doc """
  Retrieves a list of activity logs.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- permit(:all, conn.assigns),
         true <- !is_nil(query) || {:error, :unauthorized},
         %Paginator{} = paginator <- Orchestrator.query(query, ActivityLogOverlay, attrs),
         activity_logs <-
           ActivityLogGate.load_originator_and_target(paginator.data, ModuleMapper),
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
  defp permit(action, actor) do
    ActivityLogPolicy.authorize(action, actor, nil)
  end
end
