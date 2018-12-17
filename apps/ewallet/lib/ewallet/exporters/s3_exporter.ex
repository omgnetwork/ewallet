defmodule EWallet.S3Exporter do
  alias EWalletDB.{Repo, Export, Uploaders.File}
  alias EWalletConfig.Config

  @min_byte_size 5_243_000

  def upload(args, update_export) do
    case args.export.estimated_size > @min_byte_size * 2 do
      true ->
        parts = trunc(args.export.estimated_size / @min_byte_size)
        chunk_size = args.export.estimated_size / parts

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
            completion = 100
            (chunk * index) / args.export.estimated_size * 100
            {:ok, export} = update_export.(args.export, Export.processing(), completion)
          end)
          |> ExAws.S3.upload(get_bucket(), args.path)
          |> ExAws.request()
          |> case do
            {:ok, %{status_code: 200}} -> {:ok, nil}
            {:ok, :done} -> {:ok, nil}
            {:error, error} -> {:error, error}
          end
        end, timeout: :infinity)

      false ->
        # query and ...
        {:ok, data} = to_full_csv(args.query, args.serializer)

        # direct upload
        EWalletDB.Uploaders.File.store(%{
          filename: args.export.filename,
          binary: data
        })
        |> case do
          {:ok, filename} ->
            {:ok, export} = update_export.(args.export, Export.completed(), 100, filename)
          {:error, error} ->
            {:ok, export} = update_export.(args.export, Export.failed(), 0, error)
            {:error, error}
        end
    end
  end

  defp get_bucket() do
    Config.get(:aws_bucket)
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
end
