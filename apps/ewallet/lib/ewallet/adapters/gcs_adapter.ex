defmodule EWallet.GCSAdapter do
  alias EWallet.AdapterHelper
  alias EWalletDB.{Export, Uploaders}

  def generate_signed_url(export) do
    url = Uploaders.File.url({export.filename, nil}, :original, signed: true)
    {:ok, url}
  end

  def upload(args) do
    :ok = AdapterHelper.setup_local_dir()
    path = AdapterHelper.build_local_path(args.export.filename)
    chunk_size = args.export.estimated_size / 90

    {:ok, _file} = AdapterHelper.stream_to_file(path, args.export, args.query, args.serializer, chunk_size)

    case Uploaders.File.store(path) do
      {:ok, _filename} ->
        handle_successful_upload(args.export, path)
      {:error, error} ->
        {:ok, export} = AdapterHelper.store_error(args.export, error)
        {:error, export}
    end
  end

  defp handle_successful_upload(export, path) do
    {:ok, export} = AdapterHelper.update_export(export, Export.completed(), 100)
    File.rm(path)
    {:ok, export}
  end
end
