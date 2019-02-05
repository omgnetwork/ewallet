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

defmodule Utils.Helpers.PathResolver do
  @moduledoc """
  Module to interact with paths.
  """
  alias Utils.Helpers.Normalize

  @doc """
  Returns a path to static distribution. If SERVE_LOCAL_STATIC
  is true, it means that we want to serve directly from source tree
  instead of from the _build directory, so we're returning a relative
  path from a file.
  """
  def static_dir(app) do
    serve_local_static = System.get_env("SERVE_LOCAL_STATIC")

    case Normalize.to_boolean(serve_local_static) do
      true ->
        Path.expand("../../../#{app}/priv/static", __DIR__)

      false ->
        Application.app_dir(app, "priv/static")
    end
  end
end
