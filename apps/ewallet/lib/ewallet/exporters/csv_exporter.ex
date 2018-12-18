defmodule EWallet.CSVExporter do
  use GenServer
  import Ecto.Query
  alias EWallet.{S3Adapter, GCSAdapter, LocalAdapter, CSVExporter}
  alias EWalletDB.{Repo, Export, Uploaders.File}
  alias EWalletConfig.Config

  defstruct uuid: "22222222-2222-2222-2222-222222222222"

  def start(export, schema, query, serializer) do
    count = get_count(query)
    estimated_size = get_size_estimate(query, serializer)
    {:ok, export} = Export.init(export, schema, count, estimated_size, %CSVExporter{})

    {:ok, pid} = GenServer.start_link(__MODULE__, [
      export: export,
      query: query,
      serializer: serializer,
    ], name: {:global, export.uuid})

    :ok = GenServer.cast(pid, :upload)

    {:ok, pid, export}
  end

  def init(export: export, query: query, serializer: serializer) do
    {:ok, %{
      query: query,
      serializer: serializer,
      export: export
    }}
  end

  def handle_cast(:upload, state) do
    adapter_module = get_adapter_module(state.export.adapter)
    adapter_module.upload(state, &update_export/4)

    {:noreply, state}
  end

  defp update_export(export, status, completion, url \\ nil) do
    Export.update(export, %{
      originator: %CSVExporter{},
      status: status,
      completion: completion,
      url: url
    })
  end

  defp get_adapter_module(export) do
    case Config.get(:file_storage_adapter) do
      "aws"   -> S3Adapter
      "gcs"   -> GCSAdapter
      "local" -> LocalAdapter
    end
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
