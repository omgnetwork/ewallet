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
  alias Ecto.Changeset
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
    _ = Enum.each(@start_apps, &Application.ensure_all_started/1)
    _ = Enum.each(@apps, &ensure_app_started/1)

    _ = Seeder.run([{:ewallet_config, :seeds_settings}], true)

    # The success message from the seed, along with the gap before the migration task
    # starts outputting again, makes it seem that the whole execution has ended while
    # we are only halfway through. The message below suggests the user to continue waiting
    # during that silent gap.
    _ = CLI.info("Starting the settings migration task...")

    ask? = Keyword.get(opts, :ask_confirm, true)

    _ =
      :ewallet
      |> Application.get_env(:env_migration_mapping)
      |> build_migration_plan()
      |> ask_confirmation(ask?)
      |> migrate()

    _ = :init.stop()
  end

  defp build_migration_plan(mapping) do
    # Reduce the mapping into a list of migrations to be run and a list of unchanged key-values
    Enum.reduce(mapping, {[], []}, fn {env_name, setting_name}, {to_migrate, unchanged} ->
      case build_migration(setting_name, System.get_env(env_name)) do
        {:ok, value} ->
          {[{setting_name, value} | to_migrate], unchanged}

        {:unchanged, value} ->
          {to_migrate, [{setting_name, value, :unchanged} | unchanged]}

        {:error, :normalize_error, value} ->
          {to_migrate, [{setting_name, value, :normalize_error} | unchanged]}

        nil ->
          {to_migrate, unchanged}
      end
    end)
  end

  # Skips if there's no value for the given setting.
  defp build_migration(_, nil), do: nil

  # Return the value only if the value is different from what's already set.
  defp build_migration(setting_name, value) do
    case Config.get_setting(setting_name) do
      nil ->
        nil

      setting ->
        existing_value = setting.value

        # Determines if the normalized settings value is the same as in database
        case cast_env(value, setting.type) do
          {:error, :normalize_error, _} -> {:error, :normalize_error, value}
          ^existing_value -> {:unchanged, existing_value}
          casted_value -> {:ok, casted_value}
        end
    end
  end

  defp ask_confirmation({[], []}, _) do
    _ = CLI.info("No settings could be found in the environment variables.")
    :aborted
  end

  defp ask_confirmation({to_migrate, unchanged} = plan, true) do
    _ = CLI.info("The following settings will be populated into the database:\n")

    _ =
      Enum.each(to_migrate, fn {setting_name, value} ->
        CLI.info("  - #{setting_name}: \"#{value}\"")
      end)

    _ = CLI.info("The following settings will be skipped:\n")

    _ =
      Enum.each(unchanged, fn {setting_name, value, reason} ->
        reason_text =
          case reason do
            :unchanged -> "unchanged"
            :normalize_error -> "type conversion error"
          end

        CLI.info("  - #{setting_name}: \"#{value}\" (#{reason_text})")
      end)

    case CLI.confirm?("\nAre you sure to migrate these settings to the database?") do
      true ->
        plan

      false ->
        :aborted

      {:error, :normalize_error, error_message} ->
        _ = CLI.error(error_message)
        :aborted
    end
  end

  defp ask_confirmation(plan, false), do: plan

  defp migrate(:aborted) do
    _ = CLI.info("Settings migration aborted.")
  end

  defp migrate({to_migrate, unchanged}) do
    _ = CLI.info("\nMigrating the settings to the database...\n")

    _ =
      Enum.each(unchanged, fn {setting_name, value} ->
        CLI.warn("  - Skipped: `#{setting_name}` is already #{inspect(value)}.")
      end)

    {:ok, results} =
      to_migrate
      |> build_update_attrs()
      |> Config.update()

    _ =
      Enum.each(results, fn
        {setting_name, {:ok, setting}} ->
          _ = CLI.success("  - Migrated: `#{setting_name}` is now #{inspect(setting.value)}.")

        {setting_name, {:error, changeset}} ->
          error_message =
            Enum.reduce(changeset.errors, "", fn {field, {message, _}}, acc ->
              acc <> "`#{field}` #{message}. "
            end)

          _ =
            CLI.error(
              "  - Error: setting `#{setting_name}` to #{
                inspect(Changeset.get_field(changeset, :value))
              }" <>
                " returned #{error_message}"
            )
      end)

    _ = CLI.info("\nSettings migration completed. Please remove the environment variables.")
  end

  defp build_update_attrs(to_migrate) do
    _ =
      Enum.reduce(to_migrate, [{:originator, %CLIUser{}}], fn {setting_name, value}, attrs ->
        [{String.to_existing_atom(setting_name), value} | attrs]
      end)
  end

  # These cast_env/2 are private to this module because the only other place that
  # needs to convert ENV strings by config type is its sibling `Config` release task.
  defp cast_env(value, "string"), do: value
  defp cast_env(value, "integer"), do: Normalize.to_integer(value)
  defp cast_env(value, "unsigned_integer"), do: Normalize.to_integer(value)
  defp cast_env(value, "boolean"), do: Normalize.to_boolean(value)
  defp cast_env(value, "array"), do: Normalize.to_strings(value)
end
