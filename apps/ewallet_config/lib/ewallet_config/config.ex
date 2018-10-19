defmodule EWalletConfig.Config do
  @moduledoc """
  This module contain functions that allows easier application's configuration retrieval,
  especially configurations that are configured from environment variable, which this module
  casts the environment variable values from String to their appropriate types.
  """

  use GenServer
  require Logger

  alias EWalletConfig.{
    FileStorageSettingsLoader,
    Setting,
    SettingLoader
  }

  def start_link(named: true) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def stop(pid \\ __MODULE__) do
    GenServer.stop(pid)
  end

  def init(_args) do
    {:ok, []}
  end

  def register_and_load(app, settings, pid \\ __MODULE__) do
    GenServer.call(pid, {:register_and_load, app, settings})
  end

  def reload_config(pid \\ __MODULE__) do
    GenServer.call(pid, :reload)
  end

  def update(key, attrs, pid \\ __MODULE__) do
    case Setting.update(key, attrs) do
      success = {:ok, _} ->
        reload_config(pid)
        success

      error ->
        error
    end
  end

  def insert_all_defaults(opts \\ %{}, pid \\ __MODULE__) do
    :ok = Setting.insert_all_defaults(opts)
    reload_config(pid)
  end

  def handle_call({:register_and_load, app, settings}, _from, registered_apps) do
    SettingLoader.load_settings(app, settings)
    {:reply, :ok, [{app, settings} | registered_apps]}
  end

  def handle_call(:reload, _from, registered_apps) do
    Enum.each(registered_apps, fn {app, settings} ->
      SettingLoader.load_settings(app, settings)
    end)

    {:reply, :ok, registered_apps}
  end

  def load(app, name, opts \\ nil)

  def load(app, :file_storage, _opts) do
    ensure_settings_existence()
    FileStorageSettingsLoader.load(app)
  end

  def settings do
    Setting.all()
  end

  def get(key, default_value \\ nil) do
    Setting.get_value(key) || default_value
  end

  def get_default_settings, do: Setting.get_default_settings()

  def insert(attrs), do: Setting.insert(attrs)

  @doc """
  Gets the application's environment config as a boolean.

  Returns `true` if the value is one of `[true, "true", 1, "1"]`. Returns `false` otherwise.
  """
  @spec get_boolean(atom(), atom()) :: boolean()
  def get_boolean(app, key) do
    Application.get_env(app, key) in [true, "true", 1, "1"]
  end

  @doc """
  Gets the application's environment config as a string.

  Returns the string or nil.
  """
  @spec get_string(atom(), atom()) :: String.t() | nil
  def get_string(app, key) do
    Application.get_env(app, key, nil)
  end

  @doc """
  Gets the application's environment config as a list of strings.

  Returns a list of strings or an empty list.
  """
  @spec get_strings(atom(), atom()) :: [String.t()]
  def get_strings(app, key) do
    app
    |> Application.get_env(key)
    |> string_to_list()
  end

  defp string_to_list(nil), do: []

  defp string_to_list(string) do
    string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn string -> string == "" end)
  end

  defp ensure_settings_existence do
    unless Mix.env() == :test || length(Setting.all()) > 0 do
      raise ~s(Setting seeds have not been ran. You can run them with "mix seed" or "mix seed --settings".)
    end
  end
end
