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

defmodule EWalletConfig.Storage.Local do
  @moduledoc """
  Modified copy of the Arc local storage, needed to add the base URL before
  the file paths.

  Original: https://github.com/stavro/arc/blob/master/lib/arc/storage/local.ex
  """
  alias Arc.Definition.Versioning
  alias EWalletConfig.Config
  alias Utils.Helpers.PathResolver

  def get_path(destination_dir, filename) do
    Path.join([
      PathResolver.static_dir(:url_dispatcher),
      destination_dir,
      filename
    ])
  end

  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})
    path = get_path(destination_dir, file.file_name)

    path |> Path.dirname() |> File.mkdir_p!()

    _ =
      if binary = file.binary do
        File.write!(path, binary)
      else
        File.copy!(file.path, path)
      end

    {:ok, file.file_name}
  end

  def url(definition, version, file_and_scope, _options \\ []) do
    base_url = Config.get("base_url")
    local_path = build_local_path(definition, version, file_and_scope)

    url =
      if String.starts_with?(local_path, "/") do
        base_url <> local_path
      else
        base_url <> "/" <> local_path
      end

    url |> URI.encode()
  end

  def delete(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})
    path = get_path(destination_dir, file.file_name)

    File.rm(path)
  end

  defp build_local_path(definition, version, file_and_scope) do
    Path.join([
      definition.storage_dir(version, file_and_scope),
      Versioning.resolve_file_name(definition, version, file_and_scope)
    ])
  end
end
