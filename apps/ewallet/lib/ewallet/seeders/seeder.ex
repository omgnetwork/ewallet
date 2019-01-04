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

defmodule EWallet.Seeder do
  @moduledoc """
  Provides a base functions for handling seeds data.
  """

  def gather_seeds(srcs) do
    Enum.flat_map(srcs, fn {app_name, seed_name} ->
      seed_name =
        case seed_name do
          s when is_binary(s) -> s
          s when is_atom(s) -> Atom.to_string(seed_name)
        end

      app_name
      |> Application.get_env(:ecto_repos, [])
      |> Enum.flat_map(&seeds_for(&1, seed_name))
      |> Enum.flat_map(&mod_from/1)
    end)
  end

  def gather_reporters(srcs) do
    Enum.flat_map(srcs, fn {app_name, seed_name} ->
      seed_name =
        case seed_name do
          s when is_binary(s) -> s
          s when is_atom(s) -> Atom.to_string(seed_name)
        end

      app_name
      |> Application.get_env(:ecto_repos, [])
      |> Enum.map(&reporters_for(&1, seed_name))
      |> Enum.flat_map(&mod_from/1)
    end)
  end

  def argsline_for(mods) do
    Enum.flat_map(mods, fn mod ->
      Keyword.get(mod.seed, :argsline, [])
    end)
  end

  defp mod_from(file) do
    for {mod, _bin} <- Code.load_file(file), do: mod
  end

  defp seeds_for(repo, seed_name) do
    seeds_path = priv_path_for(repo, seed_name)
    query = Path.join(seeds_path, "*")
    for entry <- Path.wildcard(query), do: entry
  end

  defp reporters_for(repo, reporter_name) do
    reporters_path = priv_path_for(repo, "reporters")
    Path.join(reporters_path, "#{reporter_name}.exs")
  end

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
