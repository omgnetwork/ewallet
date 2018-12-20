defmodule EWallet.LocalAdapter do
  @moduledoc """
  Export Adapter for local storage.
  """
  alias EWallet.AdapterHelper
  alias EWalletDB.Export

  def generate_signed_url(_export) do
    {:ok, nil}
  end

  def upload(args) do
    :ok = AdapterHelper.setup_local_dir()
    path = AdapterHelper.build_local_path(args.export.filename)
    chunk_size = args.export.estimated_size / 100

    {:ok, _file} =
      AdapterHelper.stream_to_file(path, args.export, args.query, args.serializer, chunk_size)

    AdapterHelper.update_export(args.export, Export.completed(), 100, nil)
  end
end
