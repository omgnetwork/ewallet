defmodule EWallet.LocalAdapter do
  alias EWalletDB.{Repo, Export, Uploaders.File}
  alias EWalletConfig.{Config, Storage.Local}

  @min_byte_size 5_243_000

  def upload(args, update_export) do
    path = Local.get_path(File.storage_dir(nil, nil), args.export.filename)
    chunk_size = args[:estimated_size] / 100

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
      args.query
      |> Repo.stream(max_rows: 500)
      |> Stream.map(fn e -> args.serializer.serialize(e) end)
      |> CSV.encode(headers: args.serializer.columns)
      |> Stream.chunk_while("", chunk, after_chunk)
      |> Stream.with_index(1)
      |> Stream.each(fn {chunk, index} ->
        completion = chunk_size * index
        {:ok, export} = update_export.(args.export, Export.processing(), completion)
      end)
      |> Enum.into(File.stream!(path, [:write, :utf8]))
    end, timeout: :infinity)
  end
end
