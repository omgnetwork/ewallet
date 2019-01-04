# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.Exporters.LocalAdapter do
  @moduledoc """
  Export Adapter for local storage.
  """
  alias EWallet.Exporters.AdapterHelper
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
