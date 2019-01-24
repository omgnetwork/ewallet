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

defmodule EWallet.ReleaseTasks.ConfigMigration do
  @moduledoc """
  Migrates the configurations from the machine's environment variables into the database.
  """
  use EWallet.ReleaseTasks
  alias EWallet.ReleaseTasks.CLIUser
  alias EWalletConfig.Setting

  @start_apps [:logger, :postgrex, :ecto, :ewallet, :ewallet_db]
  @apps [:activity_logger, :ewallet_config]

  def run do
    :init.get_plain_arguments()
    |> assume_yes?()
    |> run()
  end

  def run(assume_yes) do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Enum.each(@apps, &ensure_app_started/1)

    :ewallet
    |> Application.get_env(:env_migration_mapping)
    |> build_migration_plan()
    |> ask_confirmation(assume_yes)
    |> migrate()

    :init.stop()
  end

  defp build_migration_plan(mapping) do
    Enum.reduce(mapping, [], fn {env_name, setting_name}, accumulator ->
      case System.get_env(env_name) do
        nil -> accumulator
        value -> [{setting_name, value} | accumulator]
      end
    end)
  end

  defp ask_confirmation(migration_plan, assume_yes)

  defp ask_confirmation([], _) do
    _ = puts("No settings could be found in the environment variables.")
    :aborted
  end

  defp ask_confirmation(migration_plan, true), do: migration_plan

  defp ask_confirmation(migration_plan, false) do
    puts("The following settings will be populated into the database:\n")

    Enum.each(migration_plan, fn {setting_name, value} ->
      puts("  - #{setting_name}: \"#{value}\"")
    end)

    confirmed? = confirm?("\nAre you sure to migrate these settings to the database?")

    case confirmed? do
      true -> migration_plan
      false -> :aborted
    end
  end

  defp migrate(:aborted) do
    puts("Settings migration aborted.")
  end

  defp migrate(migration_plan) do
    puts("\nMigrating the settings to the database...\n")
    migrate_each(migration_plan)
    puts("\nSettings migration completed. Please remove the environment variables.", :success)
  end

  defp migrate_each([]), do: :noop

  defp migrate_each([{setting_name, value} | remaining]) do
    case Setting.update(setting_name, %{value: value, originator: %CLIUser{}}) do
      {:ok, _setting} ->
        puts("  - Setting `#{setting_name}` to #{inspect(value)}... Done.")

      {:error, changeset} ->
        error_message =
          Enum.reduce(changeset.errors, "", fn {field, {message, _}}, acc ->
            acc <> "`#{field}` #{message}. "
          end)

        puts(
          "  - Setting `#{setting_name}` to #{inspect(value)}... Failed. #{error_message}",
          :error
        )
    end

    migrate_each(remaining)
  end
end
