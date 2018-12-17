defmodule EWallet.CSVExporter do
  use GenServer
  import Ecto.Query
  alias EWallet.{S3Exporter, CSVExporter}
  alias EWalletDB.{Repo, Export, Uploaders.File}
  alias EWalletConfig.Config

  defstruct uuid: "22222222-2222-2222-2222-222222222222"

  def start(export, schema, query, serializer) do
    name = "#{schema}-#{export.inserted_at}.csv"

    {:ok, pid} = GenServer.start_link(__MODULE__, [
      name: name,
      schema: schema,
      query: query,
      serializer: serializer,
      export: export
    ], name: {:global, export.uuid})

    :ok = GenServer.cast(pid, :upload)

    {:ok, export} = update_export(export, Export.processing(), 1)
    {:ok, pid, export}
  end

  def init(name: name, schema: schema, query: query, serializer: serializer, export: export) do
    {:ok, %{
      filename: name,
      path: "#{File.storage_dir(nil, nil)}/#{name}",
      schema: schema,
      query: query,
      serializer: serializer,
      export: export,
      processed_count: 0,
      total_count: 0,
      estimated_size: 0,
      adapter: get_adapter(),
      content: ""
    }}
  end

  def handle_cast(:upload, state) do
    state
    |> set_state()
    |> state.adapter.upload(
      &update_export/4
    )

    {:noreply, state}
  end

  defp get_adapter() do
    case Config.get(:file_storage_adapter) do
      "aws"   -> S3Exporter
      "gcs"   -> nil
      "local" -> nil
    end
  end

  defp update_export(export, status, completion, url \\ nil) do
    Export.update(export, %{
      originator: %CSVExporter{},
      status: status,
      completion: completion,
      url: url
    })
  end

  defp set_state(state) do
    count = get_count(state.query)
    estimated_size = get_size_estimate(state.query, state.serializer)

    state
    |> Map.put(:total_count, count)
    |> Map.put(:estimated_size, estimated_size * count)
  end

  defp get_count(query) do
    Repo.aggregate(query, :count, :uuid)
  end

  defp get_size_estimate(query, serializer) do
    query
    |> limit(10)
    |> Repo.all()
    |> serialize_sample(serializer)
    |> case do
      {:error, _} = error ->
        error
      [_columns | rows] ->
        byte_size(Enum.join(rows)) / length(rows)
    end
  end

  defp serialize_sample(sample_records, _serializer) when length(sample_records) == 0 do
    {:error, :no_records}
  end

  defp serialize_sample(sample_records, serializer) do
    sample_records
    |> Enum.map(fn r -> serializer.serialize(r) end)
    |> CSV.encode(headers: serializer.columns)
    |> Enum.to_list()
  end
end
