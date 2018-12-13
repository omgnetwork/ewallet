defmodule AdminAPI.V1.CSVExporter do
  import Plug.Conn
  import Ecto.Query
  alias EWalletDB.Repo

  def export(query, serializer, conn, filename, repo \\ Repo) do
    conn = prepare_conn_for_stream_response(conn, filename)

    {:ok, conn} =
      repo.transaction(fn ->
        query
        |> build_export_query(serializer)
        |> Enum.reduce_while(conn, fn (data, conn) ->
          case chunk(conn, data) do
            {:ok, conn} ->
              {:cont, conn}
            {:error, :closed} ->
              {:halt, conn}
          end
        end)
      end)

    conn
  end

  defp prepare_conn_for_stream_response(conn, filename) do
    conn
    |> put_resp_header("content-disposition", "attachment; filename=#{filename}.csv")
    |> put_resp_content_type("text/csv")
    |> send_chunked(200)
  end

  defp build_export_query(query, serializer, batch_size \\ 500) do
    columns = serializer.columns()
    csv_headers = [Enum.join(columns, ","), "\n"]

    query
    |> Repo.stream()
    |> Stream.map(fn e -> serializer.serialize(e) end)
    |> CSV.encode(headers: columns)
  end
end
