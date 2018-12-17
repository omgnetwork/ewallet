defmodule AdminAPI.V1.ExportController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{AccountHelper, ExportView}
  alias EWallet.ExportGate
  alias EWallet.Web.{Originator, Orchestrator, Paginator}
  alias EWalletDB.{Repo, Transaction}
  import Ecto.Query

  plug :put_view, ExportView

  def all(conn, attrs) do
    conn.assigns
    |> Originator.extract()
    |> Export.all_for()
    |> Orchestrator.query(ExportOverlay, attrs)
    |> render()
  end

  def get(conn, attrs) do

  end

  defp render(%Paginator{} = exports, conn) do
    render(conn, :exports, %{exports: paged_exports})
  end
end
