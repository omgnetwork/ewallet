defmodule EWallet.AdapterHelper do
  alias EWallet.Exporter
  alias EWalletDB.{Repo, Export, Uploaders}
  alias EWalletConfig.Storage.Local

  @rows_count 500

  def stream_to_file(path, export, query, serializer, chunk_size) do
    Repo.transaction(
      fn ->
        stream_to_chunk(export, query, serializer, chunk_size)
        |> Stream.into(File.stream!(path, [:write, :utf8]))
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  def stream_to_chunk(export, query, serializer, chunk_size) do
    chunk = fn line, {acc, count} ->
      if byte_size(acc) >= chunk_size do
        {:cont, {"#{acc}#{line}", count + 1}, {"", count + 1}}
      else
        {:cont, {"#{acc}#{line}", count + 1}}
      end
    end

    after_chunk = fn {acc, count} ->
      {:cont, {acc, count}, {"", count}}
    end

    query
    |> Repo.stream(max_rows: @rows_count)
    |> Stream.map(fn e -> serializer.serialize(e) end)
    |> CSV.encode(headers: serializer.columns)
    |> Stream.chunk_while({"", 0}, chunk, after_chunk)
    |> Stream.map(fn {chunk, count} ->
      {:ok, _export} =
        update_export(
          export,
          Export.processing(),
          # -1 for header row
          count * 100 / export.total_count - 1
        )

      chunk
    end)
  end

  def setup_local_dir do
    File.mkdir_p(local_dir())
  end

  def local_dir do
    [
      Application.get_env(:ewallet, :root),
      Uploaders.File.storage_dir(nil, nil)
    ]
    |> Path.join()
  end

  def build_local_path(filename) do
    Local.get_path(Uploaders.File.storage_dir(nil, nil), filename)
  end

  def update_export(export, status, completion, pid \\ nil) do
    Export.update(export, %{
      originator: %Exporter{},
      status: status,
      completion: completion,
      pid: pid
    })
  end

  def store_error(export, error) do
    Export.update(export, %{
      originator: %Exporter{},
      status: Export.failed(),
      failure_reason: error
    })
  end
end
