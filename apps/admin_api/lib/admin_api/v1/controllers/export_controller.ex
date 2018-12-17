defmodule AdminAPI.V1.ExportController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{AccountHelper, ExportView}
  alias EWallet.ExportGate
  alias EWallet.Web.{Originator, Orchestrator, Paginator, V1.CSV.TransactionSerializer}
  alias EWalletDB.{Repo, Transaction}
  import Ecto.Query

  plug :put_view, ExportView

  def all(conn, attrs) do

  end

  def get(conn, attrs) do

  end

  # def generate(query, conn, attrs, schema, serializer) do
  #   attrs = Originator.set_in_attrs(attrs, conn.assigns, :originator)
  #
  #
  #   render(conn, :export, %{export: export})
  # end

  @doc """
  Retrieves a list of accounts based on current account for users.
  """
  # @spec generate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  # def generate(conn, attrs) do
  #   # a = "txn_01cyp3bpt51n06khwq6c04bc4r"
  #   {:ok, pid} = EWalletDB.Exporter.start(
  #     "transactions",
  #     Transaction,
  #     Transaction, #where(Transaction, [t], t.id == ^a),
  #     TransactionSerializer
  #   )
  #
  #   send_resp(conn, 200, "")
  # end
end
