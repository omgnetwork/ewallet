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
  alias EWalletConfig.Setting

  @start_apps [:logger, :crypto, :ssl, :postgrex, :ecto, :cloak, :ewallet_db]

  def run do
    args = :init.get_plain_arguments()
    assume_yes = assume_yes?(args)

    run(assume_yes)
  end

  def run(assume_yes) do
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    :ewallet
    |> Application.get_env(:env_migration_mapping)
    |> build_migration_plan()
    |> ask_confirmation(assume_yes)
    |> migrate()

    :init.stop()
  end

  defp assume_yes?([]), do: false

  defp assume_yes?(["-y" | _t]), do: true

  defp assume_yes?(["--yes" | _t]), do: true

  defp assume_yes?(["--assume_yes" | _t]), do: true

  defp assume_yes?([_ | t]), do: assume_yes?(t)

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
    _ = print_info("No settings could be found in the environment variables.")
    :aborted
  end

  defp ask_confirmation(migration_plan, true), do: migration_plan

  defp ask_confirmation(migration_plan, false) do
    print_info("The following settings will be populated into the database:\n")

    Enum.each(migration_plan, fn {setting_name, value} ->
      print_info("  - #{setting_name}: \"#{value}\"")
    end)

    confirmed? = print_confirm?("\nAre you sure to migrate these settings to the database?")

    case confirmed? do
      true -> migration_plan
      false -> :aborted
    end
  end

  defp migrate(:aborted) do
    print_info("Settings migration aborted.")
  end

  defp migrate(migration_plan) do
    print_info("\nMigrating the settings to the database...\n")
    migrate_each(migration_plan)
    print_info("\nSettings migration completed. Please remove the environment variables.")
  end

  defp migrate_each([]), do: :noop

  defp migrate_each([{setting_name, value} | remaining]) do
    case Setting.update(setting_name, %{value: value}) do
      {:ok, _setting} ->
        print_success("  - Setting `#{setting_name}` to #{inspect(value)}... Done.")

      {:error, changeset} ->
        error_message =
          Enum.reduce(changeset.errors, "", fn {field, {message, _}}, acc ->
            acc <> "`#{field}` #{message}. "
          end)

        print_error(
          "  - Setting `#{setting_name}` to #{inspect(value)}... Failed. #{error_message}"
        )
    end

    migrate_each(remaining)
  end

  defp print_info(message), do: Mix.shell().info(message)
  defp print_confirm?(message), do: Mix.shell().yes?(message)
  defp print_success(message), do: Mix.shell().info([:green, :bright, message])
  defp print_error(message), do: Mix.shell().error(message)
end
