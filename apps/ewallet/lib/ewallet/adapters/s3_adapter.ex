defmodule EWallet.S3Adapter do
  alias EWallet.AdapterHelper
  alias EWalletDB.{Repo, Export, Uploaders}
  alias EWalletConfig.Config

  @min_byte_size 5_243_000

  def generate_signed_url(export) do
    {:ok, Uploaders.File.url({export.filename, nil}, :original, signed: true)}
  end

  def upload(args) do
    case args.export.estimated_size > @min_byte_size * 2 do
      true ->
        parts = trunc(args.export.estimated_size / @min_byte_size)
        chunk_size = args.export.estimated_size / parts

        Repo.transaction(fn ->
          args.export
          |> AdapterHelper.stream_to_chunk(args.query, args.serializer, chunk_size)
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
        Uploaders.File.store(%{
          filename: args.export.filename,
          binary: data
        })
        |> case do
          {:ok, filename} ->
            AdapterHelper.update_export(args.export, Export.completed(), 100)
          {:error, error} ->
            {:ok, export} = AdapterHelper.store_error(args.export, error)
            {:error, export}
        end
    end
  end

  defp get_bucket() do
    Application.get_env(:ewallet, :aws_bucket)
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
