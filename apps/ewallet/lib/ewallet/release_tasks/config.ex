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

defmodule EWallet.ReleaseTasks.Config do
  @moduledoc """
  A release task that manages application configurations.
  """
  use EWallet.ReleaseTasks
  alias EWallet.CLI
  alias EWallet.ReleaseTasks.CLIUser
  alias EWalletConfig.Config
  alias Utils.Helpers.Normalize

  @start_apps [:crypto, :ssl, :postgrex, :ecto_sql, :telemetry, :cloak, :ewallet]
  @apps [:activity_logger, :ewallet_config]

  def run do
    case :init.get_plain_arguments() do
      [key, value] ->
        config_base64(key, value)

      _ ->
        give_up()
    end
  end

  def run(key, value), do: config_base64(key, value)

  defp config_base64(k, v) when is_list(k) do
    case Base.decode64(to_string(k)) do
      {:ok, key} ->
        config_base64(key, v)

      _ ->
        give_up()
    end
  end

  defp config_base64(k, v) when is_list(v) do
    case Base.decode64(to_string(v)) do
      {:ok, value} ->
        config_base64(k, value)

      _ ->
        give_up()
    end
  end

  defp config_base64(key, value) do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Enum.each(@apps, &ensure_app_started/1)

    case do_set_config(key, value) do
      {:ok, setting} ->
        CLI.success("Updated: `#{key}` is now #{inspect(setting.value)}.")
        :init.stop()

      {:unchanged, value} ->
        CLI.warn("Skipped: `#{key}` is already set to #{inspect(value)}.")
        :init.stop()

      {:error, :setting_not_found} ->
        CLI.error(
          "Error: `#{key}` is not a valid settings." <>
            " Please check that the given settings name is correct and settings have been seeded."
        )

        :init.stop(1)

      {:error, changeset} ->
        error_message =
          Enum.reduce(changeset.errors, "", fn {field, {message, _}}, acc ->
            acc <> "`#{field}` #{message}. "
          end)

        CLI.error("Error: setting `#{key}` to #{inspect(value)} returned #{error_message}")
        :init.stop(1)

      {:error, :normalize_error, error_message} ->
        CLI.error("Error: setting `#{key}` to #{inspect(value)}. #{error_message}")
        :init.stop(1)

      _ ->
        give_up()
    end
  end

  defp do_set_config(key, value) do
    case Config.get_setting(key) do
      nil ->
        {:error, :setting_not_found}

      %{value: existing, type: type} ->
        case cast_env(value, type) do
          {:error, _, _} = error -> error
          ^existing -> {:unchanged, existing}
          casted_value -> do_update(key, casted_value)
        end
    end
  end

  defp do_update(key, value) do
    # The GenServer will return {:ok, result}, where the result is the actual
    # {:ok, _} | {:error, _} of the operation, so we need to return only the result.
    {:ok, result} = Config.update(%{key => value, :originator => %CLIUser{}})
    Enum.find_value(result, fn {^key, v} -> v end)
  end

  # These cast_env/2 are private to this module because the only other place that
  # needs to convert ENV strings by config type is its sibling `ConfigMigration` release task.
  defp cast_env(value, "string"), do: value
  defp cast_env(value, "integer"), do: Normalize.to_integer(value)
  defp cast_env(value, "unsigned_integer"), do: Normalize.to_integer(value)
  defp cast_env(value, "boolean"), do: Normalize.to_boolean(value)
  defp cast_env(value, "array"), do: Normalize.to_strings(value)
end
