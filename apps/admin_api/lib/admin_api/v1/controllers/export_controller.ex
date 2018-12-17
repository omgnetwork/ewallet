defmodule AdminAPI.V1.ExportController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{AccountHelper, ExportView}
  alias EWallet.ExportGate
  alias EWallet.Web.{Originator, Orchestrator, Paginator}
  alias EWalletDB.{Repo, Export}
  import Ecto.Query

  def all(conn, attrs) do
    conn.assigns
    |> Originator.extract()
    |> Export.all_for()
    |> Orchestrator.query(ExportOverlay, attrs)
    |> render_exports(conn)
  end

  def get(conn, attrs) do

  end

  defp render_exports(%Paginator{} = paged_exports, conn) do
    render(conn, :exports, %{exports: paged_exports})
  end
end
