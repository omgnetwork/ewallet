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

defmodule EWalletConfig.SettingLoader do
  @moduledoc """
  Load the settings from the database into the application envs.
  """
  require Logger
  alias EWalletConfig.{Setting, FileStorageSettingsLoader}

  def load_settings(app, settings) when is_atom(app) and is_list(settings) do
    stored_settings = Setting.all() |> Enum.into(%{}, fn s -> {s.key, s} end)

    Enum.each(settings, fn key ->
      load_setting(app, key, stored_settings)
    end)

    if Enum.member?(settings, :file_storage_adapter) do
      FileStorageSettingsLoader.load(app)
    end
  end

  def load_settings(_, _, _), do: nil

  def load_setting(app, {setting, keys}, stored_settings) do
    Application.put_env(app, setting, build_values_map(app, keys, stored_settings))
  end

  def load_setting(app, key, stored_settings) do
    Application.put_env(app, key, fetch_value(app, key, stored_settings))
  end

  defp build_values_map(app, keys, stored_settings) do
    Enum.into(keys, %{}, fn key -> handle_mapped_keys(app, key, stored_settings) end)
  end

  defp handle_mapped_keys(app, {db_setting_name, app_setting_name}, stored_settings)
       when is_atom(app_setting_name) do
    {app_setting_name, fetch_value(app, db_setting_name, stored_settings)}
  end

  defp handle_mapped_keys(app, key, stored_settings) do
    {key, fetch_value(app, key, stored_settings)}
  end

  defp fetch_value(app, key, stored_settings) do
    case Map.get(stored_settings, Atom.to_string(key)) do
      nil ->
        if Application.get_env(:ewallet, :env) != :test, do: warn(app, key)
        nil

      setting ->
        map_value(key, setting.value)
    end
  end

  defp map_value(key, value) when is_atom(key) do
    str_key = Atom.to_string(key)
    map_value(str_key, value)
  end

  defp map_value(key, value) when is_binary(key) do
    mappings = Setting.get_setting_mappings()

    case Map.get(mappings, key) do
      nil ->
        value

      mapping ->
        case Map.get(mapping, value) do
          nil -> mapping["_"]
          mapped_value -> mapped_value
        end
    end
  end

  def warn(app, key) do
    Logger.warn(~s([Configuration] Setting "#{key}" used by "#{app}" not found.))
  end
end
