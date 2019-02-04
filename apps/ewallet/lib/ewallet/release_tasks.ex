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

defmodule EWallet.ReleaseTasks do
  @moduledoc """
  Provides utility function for release tasks.
  """
  alias EWallet.CLI

  defmacro __using__(_opts) do
    quote do
      import EWallet.ReleaseTasks
    end
  end

  def ensure_app_started({app_name, _}), do: ensure_app_started(app_name)

  def ensure_app_started(app_name) do
    case Application.ensure_all_started(app_name) do
      {:ok, _} ->
        repos = Application.get_env(app_name, :ecto_repos, [])
        Enum.each(repos, & &1.start_link(pool_size: 2))

      _ ->
        nil
    end
  end

  def give_up do
    CLI.error("Error: unknown error occured in release tasks. This is probably a bug.")
    CLI.error("Please file a bug report at https://github.com/omisego/ewallet/issues/new")
    :init.stop(1)
  end
end
