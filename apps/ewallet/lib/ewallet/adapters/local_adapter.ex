defmodule EWallet.LocalAdapter do
  alias EWallet.AdapterHelper

  def generate_signed_url(_export) do
    {:ok, nil}
  end

  def upload(args) do
    :ok = AdapterHelper.setup_local_dir()
    path = AdapterHelper.build_local_path(args.export.filename)
    chunk_size = args.export.estimated_size / 100

    {:ok, _file} = AdapterHelper.stream_to_file(path, args.export, args.query, args.serializer, chunk_size)

    {:ok, args.export}
  end
end
