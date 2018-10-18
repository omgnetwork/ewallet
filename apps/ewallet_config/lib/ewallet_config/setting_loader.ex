defmodule EWalletConfig.SettingLoader do
  require Logger
  alias EWalletConfig.Setting
  
  def load_settings(app, settings) do
    Enum.each(settings, fn key ->
      load_setting(app, key)
    end)
  end

  def load_setting(app, {setting, keys}) do
    Application.put_env(app, setting, build_values_map(app, keys))
  end

  def load_setting(app, key) do
    Application.put_env(app, key, fetch_value(app, key))
  end

  defp build_values_map(app, keys) do
    keys
    |> Enum.map(fn key -> handle_mapped_keys(app, key) end)
    |> Enum.into(%{})
  end

  defp handle_mapped_keys(app, {db_setting_name, app_setting_name}) when is_atom(app_setting_name) do
    {app_setting_name, fetch_value(app, db_setting_name)}
  end

  defp handle_mapped_keys(app, key) do
    {key, fetch_value(app, key)}
  end

  defp fetch_value(app, key) do
    case Setting.get(key) do
      nil ->
        if Mix.env != :test, do: warn(app, key)
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
          nil  -> mapping["_"]
          mapped_value -> mapped_value
        end
    end
  end

  def warn(app, key) do
    Logger.warn(~s([Configuration] Setting "#{key}" used by "#{app}" not found.))
  end
end
