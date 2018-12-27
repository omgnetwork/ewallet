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

defmodule AdminAPI.V1.ExportController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{ExportGate, ExportPolicy}
  alias EWallet.Web.{Originator, Orchestrator, Paginator, V1.ExportOverlay}
  alias EWalletDB.Export

  def all(conn, attrs) do
    conn.assigns
    |> Originator.extract()
    |> Export.all_for()
    |> Orchestrator.query(ExportOverlay, attrs)
    |> render_exports(conn)
  end

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id} = attrs) do
    with %Export{} = export <- Export.get(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, export),
         {:ok, url} <- ExportGate.generate_url(export),
         export <- Map.put(export, :url, url),
         {:ok, export} <- Orchestrator.one(export, ExportOverlay, attrs) do
      render(conn, :export, %{export: export})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  def download(conn, %{"id" => id}) do
    with %Export{} = export <- Export.get(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, export),
         true <- export.adapter == "local" || {:error, :export_not_local},
         path <- Path.join(Application.get_env(:ewallet, :root), export.path),
         true <- File.exists?(path) || {:error, :file_not_found} do
      send_download(
        conn,
        {:file, path},
        filename: export.filename,
        content_type: "text/csv",
        charset: "utf-8"
      )
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  def download(conn, _), do: handle_error(conn, :invalid_parameter)

  defp render_exports(%Paginator{} = paged_exports, conn) do
    render(conn, :exports, %{exports: paged_exports})
  end

  defp render_exports({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @spec permit(:all | :create | :get | :update, map(), String.t() | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, export) do
    Bodyguard.permit(ExportPolicy, action, params, export)
  end
end
