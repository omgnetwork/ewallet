defmodule AdminAPI.V1.ExportController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias EWallet.AccountPolicy
  alias EWallet.Web.{Orchestrator, Paginator, V1.CSV.TransactionSerializer}
  alias EWalletDB.{Repo, Transaction}
  import Ecto.Query

  @doc """
  Retrieves a list of accounts based on current account for users.
  """
  @spec generate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def generate(conn, attrs) do
    # AdminAPI.V1.CSVExporter.export(Transaction, TransactionSerializer, conn, "med")
    columns = TransactionSerializer.columns()
    csv_headers = [Enum.join(columns, ","), "\n"]
    a = "txn_01cydv4k718j5ckh7gbxkfzzpc"
    IO.inspect("running!!")

    IO.inspect Repo.transaction fn ->
      Transaction
      # |> where([t], t.id == ^a)
      |> Repo.stream()
      |> Stream.map(fn e -> TransactionSerializer.serialize(e) end)
      |> CSV.encode(headers: columns)
      |> Enum.into(File.stream!("/Users/thibaultdenizet/src/ewallet/outputz.csv", [:write, :utf8]))
    end
    # |> Enum.to_list()
    # |> Stream.each(fn e ->
    #   IO.inspect(e)
    # end)
    #
    # |> Stream.run()

    send_resp(conn, 200, "")
  end
end
