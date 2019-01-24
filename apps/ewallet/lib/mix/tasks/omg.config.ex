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

defmodule Mix.Tasks.Omg.Config do
  @moduledoc """
  Manage application configurations.

  ## Examples

  To set a configuration value:

      mix omg.config "key" "value"

  You may also pass a set of configuration values as json:

      mix omg.config '{"key1": "value1", "key2": "value2"}'

  To migrate all settings from environment variables to the database::

      mix omg.config --migrate

  You will be asked to confirm the values before the migration begins.
  You may provide flag `-y`, `--yes` or `--assume_yes` to skip the confirmation.
  """
  use Mix.Task
  alias EWallet.CLI
  alias EWallet.ReleaseTasks.{Config, ConfigMigration}

  @strict_switches [
    yes: :boolean,
    assume_yes: :boolean,
    migrate: :boolean
  ]

  @aliases [
    m: :migrate,
    y: :yes,
  ]

  def run(args) do
    _ = CLI.configure_logger()

    args
    |> OptionParser.parse(strict: @strict_switches, aliases: @aliases)
    |> do_run()
  end

  # Entry point for setting a configuration given a key and a value
  defp do_run({[], [key, value], []}) do
    Config.run(key, value)
  end

  # Entry point for migrating the configurations
  defp do_run({[migrate: true], [], []}) do
    ConfigMigration.run()
  end

  # Entry point for migrating the configurations and skipping the confirmation
  defp do_run({[migrate: true, assume_yes: true], [], []}) do
    ConfigMigration.run(ask_confirm: false)
  end

  defp do_run({[migrate: true, yes: true], [], []}) do
    ConfigMigration.run(ask_confirm: false)
  end

  # Fallback
  defp do_run({_, _, _}) do
    Mix.Tasks.Help.run(["omg.config"])
  end
end
