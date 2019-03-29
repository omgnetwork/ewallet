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

defmodule EWallet.ReleaseTasks.ConfigMigration do
  @moduledoc """
  A release task that migrates the configurations from the machine's
  environment variables into the database.
  """
  use EWallet.ReleaseTasks
  alias EWallet.CLI
  alias EWallet.ReleaseTasks.CLIUser
  alias EWallet.Seeder.CLI, as: Seeder
  alias EWalletConfig.Config
  alias Utils.Helpers.Normalize

  @start_apps [:logger, :postgrex, :ecto_sql, :telemetry, :ewallet, :ewallet_db]
  @apps [:activity_logger, :ewallet_config]

  def run_ask_confirm, do: run(ask_confirm: true)

  def run_skip_confirm, do: run(ask_confirm: false)

  def run(opts \\ []) do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Enum.each(@apps, &ensure_app_started/1)

    _ = Seeder.run([{:ewallet_config, :seeds_settings}], true)

    # The success message from the seed, along with the gap before the migration task
    # starts outputting again, makes it seem that the whole execution has ended while
    # we are only halfway through. The message below suggests the user to continue waiting
    # during that silent gap.
    CLI.info("Starting the settings migration task...")

    ask? = Keyword.get(opts, :ask_confirm, true)

    :ewallet
    |> Application.get_env(:env_migration_mapping)
    |> build_migration_plan()
    |> ask_confirmation(ask?)
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

  defp ask_confirmation([], _) do
    _ = CLI.info("No settings could be found in the environment variables.")
    :aborted
  end

  defp ask_confirmation(migration_plan, true) do
    CLI.info("The following settings will be populated into the database:\n")

    Enum.each(migration_plan, fn {setting_name, value} ->
      CLI.info("  - #{setting_name}: \"#{value}\"")
    end)

    confirmed? = CLI.confirm?("\nAre you sure to migrate these settings to the database?")

    case confirmed? do
      true -> migration_plan
      false -> :aborted
    end
  end

  defp ask_confirmation(migration_plan, false), do: migration_plan

  defp migrate(:aborted) do
    CLI.info("Settings migration aborted.")
  end

  defp migrate(migration_plan) do
    CLI.info("\nMigrating the settings to the database...\n")
    migrate_each(migration_plan)
    CLI.info("\nSettings migration completed. Please remove the environment variables.")
  end

  defp migrate_each([]), do: :noop

  defp migrate_each([{setting_name, value} | remaining]) do
    case do_migrate(setting_name, value) do
      {:ok, setting} ->
        CLI.success("  - Migrated: `#{setting_name}` is now #{inspect(setting.value)}.")

      {:unchanged, value} ->
        CLI.warn("  - Skipped: `#{setting_name}` is already set to #{inspect(value)}.")

      {:error, changeset} ->
        error_message =
          Enum.reduce(changeset.errors, "", fn {field, {message, _}}, acc ->
            acc <> "`#{field}` #{message}. "
          end)

        CLI.error(
          "  - Error: setting `#{setting_name}` to #{inspect(value)} returned #{error_message}"
        )
    end

    migrate_each(remaining)
  end

  defp do_migrate(setting_name, value) do
    setting = Config.get_setting(setting_name)
    existing = setting.value

    case cast_env(value, setting.type) do
      ^existing -> {:unchanged, existing}
      casted_value -> Config.update(%{setting_name: casted_value, originator: %CLIUser{}})
    end
  end

  # These cast_env/2 are private to this module because the only other place that
  # needs to convert ENV strings by config type is its sibling `Config` release task.
  defp cast_env(value, "string"), do: value
  defp cast_env(value, "integer"), do: Normalize.to_integer(value)
  defp cast_env(value, "unsigned_integer"), do: Normalize.to_integer(value)
  defp cast_env(value, "boolean"), do: Normalize.to_boolean(value)
  defp cast_env(value, "array"), do: Normalize.to_strings(value)
end
