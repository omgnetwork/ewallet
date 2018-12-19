defmodule EWallet.AdapterHelper do
  alias EWallet.Exporter
  alias EWalletDB.{Repo, Export, Uploaders}
  alias EWalletConfig.{Config, Storage.Local}

  @rows_count 500

  def stream_to_file(path, export, query, serializer, chunk_size) do
    Repo.transaction(fn ->
      stream_to_chunk(export, query, serializer, chunk_size)
      |> Stream.into(File.stream!(path, [:write, :utf8]))
      |> Stream.run()
    end, timeout: :infinity)
  end

  def stream_to_chunk(export, query, serializer, chunk_size) do
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

    query
    |> Repo.stream(max_rows: @rows_count)
    |> Stream.map(fn e -> serializer.serialize(e) end)
    |> CSV.encode(headers: serializer.columns)
    |> Stream.chunk_while("", chunk, after_chunk)
    |> Stream.with_index(1)
    |> Stream.map(fn {chunk, index} ->
      {:ok, export} = update_export(
        export,
        Export.processing(),
        chunk_size * index
      )

      chunk
    end)
  end

  def setup_local_dir do
    File.mkdir_p(Uploaders.File.storage_dir(nil, nil))
  end

  def build_local_path(filename) do
    Local.get_path(Uploaders.File.storage_dir(nil, nil), filename)
  end

  def update_export(export, status, completion) do
    Export.update(export, %{
      originator: %Exporter{},
      status: status,
      completion: completion
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
