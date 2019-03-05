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

defmodule Mix.Tasks.Omg.Seed do
  @moduledoc """
  Create initial seed data.

  ## Examples

  Simply run the following command:

      mix omg.seed
  """
  use Mix.Task
  alias EWallet.CLI
  alias EWallet.Seeder.CLI, as: SeederCLI

  @shortdoc "Create initial seed data"
  @start_apps [:logger, :crypto, :ssl, :postgrex, :ecto, :cloak]
  @repo_apps [:ewallet_db, :local_ledger_db]
  @e2e_disabled_warning """
  Test seeds can only be ran if the environment variable `E2E_ENABLED` is set to `true`
  """

  def run(args) do
    _ = CLI.configure_logger()

    spec = seed_spec(args)
    assume_yes = assume_yes?(args)

    Enum.each(@start_apps, &Application.ensure_all_started/1)

    Enum.each(@repo_apps, &ensure_started/1)
    SeederCLI.run(spec, assume_yes)
  end

  #
  # Booting
  #

  defp ensure_started(app_name) do
    case Application.ensure_all_started(app_name) do
      {:ok, _} ->
        repos = Application.get_env(app_name, :ecto_repos, [])
        Enum.each(repos, & &1.start_link(pool_size: 2))

      _ ->
        nil
    end
  end

  #
  # Seed specs
  #

  defp seed_spec([]) do
    seed_spec(["--settings"]) ++ [{:ewallet_db, :seeds}]
  end

  defp seed_spec(["--settings" | _t]) do
    [{:ewallet_config, :seeds_settings}]
  end

  defp seed_spec(["--sample" | t]) do
    seed_spec(t) ++ [{:ewallet_db, :seeds_sample}]
  end

  defp seed_spec(["--test" | _t]) do
    e2e_enabled = System.get_env("E2E_ENABLED") || "false"

    case Regex.match?(~r/^(t(rue)?|y(es)?|on|1)$/, e2e_enabled) do
      true ->
        seed_spec(["--settings"]) ++ [{:ewallet_db, :seeds_test}]

      false ->
        IO.puts(@e2e_disabled_warning)
        []
    end
  end

  defp seed_spec([_ | t]) do
    seed_spec(t)
  end

  defp assume_yes?([]), do: false

  defp assume_yes?(["-y" | _t]), do: true

  defp assume_yes?(["--yes" | _t]), do: true

  defp assume_yes?(["--assume_yes" | _t]), do: true

  defp assume_yes?([_ | t]), do: assume_yes?(t)
end
