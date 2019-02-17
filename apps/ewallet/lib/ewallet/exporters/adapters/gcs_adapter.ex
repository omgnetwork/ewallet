# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.Exporters.GCSAdapter do
  @moduledoc """
  Export Adapter for Google Cloud Storage.
  """
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

    {:ok, _file} =
      AdapterHelper.stream_to_file(
        path,
        args.export,
        args.query,
        args.preloads,
        args.serializer,
        chunk_size
      )

    case Uploaders.File.store(path) do
      {:ok, _filename} ->
        handle_successful_upload(args.export, path)

      {:error, error} ->
        handle_failed_upload(args.export, path, error)
    end
  end

  defp handle_successful_upload(export, path) do
    {:ok, export} = AdapterHelper.update_export(export, Export.completed(), 100, nil)
    _ = File.rm(path)
    {:ok, export}
  end

  defp handle_failed_upload(export, path, error) do
    {:ok, export} = AdapterHelper.store_error(export, "Upload failed.", inspect(error))
    _ = File.rm(path)
    {:error, export}
  end
end
