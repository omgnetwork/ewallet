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


  @spec start_link(Map.t()) :: {:ok, pid()} | {:error, Atom.t()}
  def start_link(named: true) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_link() :: {:ok, pid()} | {:error, Atom.t()}
  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  @spec start_link(pid()) :: :ok | {:error, Atom.t()}
  def stop(pid \\ __MODULE__) do
    GenServer.stop(pid)
  end

  @spec start_link(Map.t()) :: {:ok, []}
  def init(_args) do
    {:ok, []}
  end

  @spec handle_call(:get_registered_apps, Atom.t(), [Atom.t()]) :: [{Atom.t(), [Atom.t]}]
  def handle_call(:get_registered_apps, _from, registered_apps) do
    {:reply, registered_apps, registered_apps}
  end

  @spec handle_call(:register_and_load, Atom.t(), [Atom.t()]) :: [Atom.t()]
  def handle_call({:register_and_load, app, settings}, _from, registered_apps) do
    SettingLoader.load_settings(app, settings)
    {:reply, :ok, [{app, settings} | registered_apps]}
  end

  @spec handle_call(:reloads, Atom.t(), [Atom.t()]) :: :ok
  def handle_call(:reload, _from, registered_apps) do
    Enum.each(registered_apps, fn {app, settings} ->
      SettingLoader.load_settings(app, settings)
    end)

    {:reply, :ok, registered_apps}
  end

  @spec get_registered_apps(pid()) :: [{Atom.t(), [Atom.t]}]
  def get_registered_apps(pid \\ __MODULE__) do
    GenServer.call(pid, :get_registered_apps)
  end

  @spec register_and_load(Atom.t(), [Atom.t()]) :: [{Atom.t(), [Atom.t]}]
  def register_and_load(app, settings, pid \\ __MODULE__) do
    GenServer.call(pid, {:register_and_load, app, settings})
  end

  @spec reload_config(Atom.t()) :: :ok
  def reload_config(pid \\ __MODULE__) do
    case Node.list() do
      [] ->
        GenServer.call(pid, :reload)
      _nodes ->
        GenServer.multi_call(pid, :reload)
    end
  end

  @spec update(String.t(), Map.t(), Atom.t()) :: {:ok, %Setting{}} | {:error, Atom.t()}
  def update(key, attrs, pid \\ __MODULE__) do
    case Setting.update(key, attrs) do
      success = {:ok, _} ->
        reload_config(pid)
        success

      error ->
        error
    end
  end

  @spec update_all(Map.t(), Atom.t()) :: [{:ok, %Setting{}} | {:error, Atom.t()}]
  def update_all(attrs, pid \\ __MODULE__) do
    res = Setting.update_all(attrs)
    reload_config(pid)
    res
  end

  @spec insert_all_defaults(Map.t(), Atom.t()) :: :ok
  def insert_all_defaults(opts \\ %{}, pid \\ __MODULE__) do
    :ok = Setting.insert_all_defaults(opts)
    reload_config(pid)
  end

  @spec settings() :: [%Setting{}]
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
