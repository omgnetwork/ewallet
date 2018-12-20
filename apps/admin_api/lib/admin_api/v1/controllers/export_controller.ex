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
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :export_id_not_found)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  def download(conn, %{"id" => id}) do
    with %Export{} = export <- Export.get(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, export),
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
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :export_id_not_found)
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
