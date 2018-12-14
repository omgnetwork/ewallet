defmodule EWalletDB.Exporter do
  use GenServer
  import Ecto.Query
  alias EWalletDB.Repo

  @min_byte_size 5_243_000

  def start(name, schema, query, serializer) do
    {:ok, state} = init(name, schema, query, serializer)
    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    :ok = GenServer.cast(pid, :upload)

    {:ok, pid}
  end

  def init(name, schema, query, serializer) do
    {:ok, %{
      filename: name,
      schema: schema,
      query: query,
      serializer: serializer,
      processed_count: 0,
      total_count: 0,
      estimated_size: 0,
      content: ""
    }}
  end

  def handle_cast(:upload, state) do
    state = set_state(state)

    case state[:estimated_size] > @min_byte_size * 2 do
      true ->
        parts = trunc(state[:estimated_size] / @min_byte_size)
        chunk_size = state[:estimated_size] / parts

        chunk = fn line, acc ->
          {:cont, "#{acc}#{line}"}
        end

        after_chunk = fn acc ->
          if byte_size(acc) >= chunk_size do
            {:cont, acc, ""}
          else
            {:cont, acc}
          end
        end

        Repo.transaction(fn ->
          state.query
          |> Repo.stream(max_rows: 500)
          |> Stream.map(fn e -> state.serializer.serialize(e) end)
          |> CSV.encode(headers: state.serializer.columns)
          |> Stream.chunk_while("", chunk, after_chunk)
          |> ExAws.S3.upload("testouille", "private/uploads/#{Mix.env()}/exports/#{state.filename}#{DateTime.utc_now()}.csv")
          |> ExAws.request()
          |> case do
            {:ok, %{status_code: 200}} -> {:ok, nil}
            {:ok, :done} -> {:ok, nil}
            {:error, error} -> {:error, error}
          end
        end, timeout: :infinity)

      false ->
        # query and ...
        {:ok, data} = to_full_csv(state.query, state.serializer)

        # direct upload
        EWalletDB.Uploaders.File.store(%{
          filename: "#{state.filename}-#{DateTime.utc_now()}.csv",
          binary: data
        })
    end

    {:noreply, state}
  end

  defp set_state(state) do
    count = get_count(state.query)
    estimated_size = get_size_estimate(state.schema, state.serializer)

    state
    |> Map.put(:total_count, count)
    |> Map.put(:estimated_size, estimated_size * count)
  end

  defp to_full_csv(query, serializer) do
    Repo.transaction fn ->
      query
      |> Repo.stream(max_rows: 500)
      |> Stream.map(fn e ->
        serializer.serialize(e)
      end)
      |> CSV.encode(headers: serializer.columns)
      |> Enum.join("")
    end
  end

  defp get_count(query) do
    Repo.aggregate(query, :count, :uuid)
  end

  defp get_size_estimate(schema, serializer) do
    tmp_record = Repo.one(from t in schema, order_by: [desc: t.id], limit: 1)

    [serializer.serialize(tmp_record)]
    |> CSV.encode(headers: serializer.columns)
    |> Enum.to_list()
    |> Enum.at(1)
    |> byte_size()
  end
end
