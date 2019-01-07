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

defmodule EWalletConfig.Config do
  @moduledoc """
  This module contain functions that allows easier application's configuration retrieval,
  especially configurations that are configured from environment variable, which this module
  casts the environment variable values from String to their appropriate types.
  """

  use GenServer
  require Logger

  alias EWalletConfig.Repo

  alias EWalletConfig.{
    Setting,
    SettingLoader
  }

  @spec init(Map.t()) :: {:ok, []}
  def init(_args) do
    {:ok, []}
  end

  @spec start_link() :: GenServer.on_start()
  def start_link, do: start_link([])

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(args) do
    {opts, args} =
      case Keyword.pop(args, :named) do
        {true, popped} -> {[name: __MODULE__], popped}
        {_, popped} -> {[], popped}
      end

    GenServer.start_link(__MODULE__, args, opts)
  end

  @spec stop(pid()) :: :ok
  def stop(pid \\ __MODULE__) do
    GenServer.stop(pid)
  end

  @spec handle_call(:get_registered_apps, Atom.t(), [Atom.t()]) :: [{Atom.t(), [Atom.t()]}]
  def handle_call(:get_registered_apps, _from, registered_apps) do
    {:reply, registered_apps, registered_apps}
  end

  @spec handle_call(:register_and_load, atom(), [atom()]) :: [atom()]
  def handle_call({:register_and_load, app, settings}, _from, registered_apps) do
    SettingLoader.load_settings(app, settings)
    {:reply, :ok, [{app, settings} | registered_apps]}
  end

  def handle_call({:update_and_reload, attrs}, _from, registered_apps) do
    res =
      Repo.transaction(fn ->
        _settings = Setting.lock_all()
        settings = Setting.update_all(attrs)
        reload_registered_apps(registered_apps)
        trigger_nodes_reload()

        settings
      end)

    {:reply, res, registered_apps}
  end

  @spec handle_call(:reload, atom(), [atom()]) :: :ok
  def handle_call(:reload, _from, registered_apps) do
    reload_registered_apps(registered_apps)
    {:reply, :ok, registered_apps}
  end

  @spec get_registered_apps(pid()) :: [{atom(), [atom()]}]
  def get_registered_apps(pid \\ __MODULE__) do
    GenServer.call(pid, :get_registered_apps)
  end

  @spec register_and_load(atom(), [atom()]) :: [{atom(), [atom()]}]
  def register_and_load(app, settings, pid \\ __MODULE__)

  def register_and_load(app, settings, {name, node}) do
    GenServer.call({name, node}, {:register_and_load, app, settings})
  end

  def register_and_load(app, settings, pid) do
    GenServer.call(pid, {:register_and_load, app, settings})
  end

  @spec reload_config(atom()) :: :ok
  def reload_config(pid \\ __MODULE__) do
    GenServer.call(pid, :reload)
    trigger_nodes_reload()
  end

  defp reload_registered_apps(registered_apps) do
    Enum.each(registered_apps, fn {app, settings} ->
      SettingLoader.load_settings(app, settings)
    end)
  end

  defp trigger_nodes_reload do
    Enum.each(Node.list(), fn node ->
      GenServer.call({__MODULE__, node}, :reload)
    end)
  end

  @spec update(map(), atom()) :: [
          {:ok, %Setting{}} | {:error, Ecto.Changeset.t()} | {:error, atom()}
        ]
  def update(attrs, pid \\ __MODULE__) do
    {config_pid, attrs} = get_config_pid(attrs)

    case Application.get_env(:ewallet, :env) == :test do
      true ->
        GenServer.call(config_pid || pid, {:update_and_reload, attrs})

      false ->
        GenServer.call(__MODULE__, {:update_and_reload, attrs})
    end
  end

  defp get_config_pid(%{config_pid: config_pid} = attrs),
    do: {config_pid, Map.delete(attrs, :config_pid)}

  defp get_config_pid(%{"config_pid" => config_pid} = attrs),
    do: {config_pid, Map.delete(attrs, "config_pid")}

  defp get_config_pid(attrs) when is_list(attrs) do
    case Keyword.fetch(attrs, :config_pid) do
      :error ->
        {nil, attrs}

      {:ok, config_pid} ->
        {config_pid, Keyword.delete(attrs, :config_pid)}
    end
  end

  defp get_config_pid(attrs), do: {nil, attrs}

  @spec insert_all_defaults(map(), map(), atom()) :: :ok
  def insert_all_defaults(originator, opts \\ %{}, pid \\ __MODULE__) do
    :ok = Setting.insert_all_defaults(originator, opts)
    reload_config(pid)
  end

  @spec settings() :: [%Setting{}]
  def settings do
    Setting.all()
  end

  def query_settings do
    Setting.query()
  end

  @spec get_setting(String.t()) :: %Setting{}
  def get_setting(key) do
    Setting.get(key)
  end

  @spec get(String.t(), any()) :: any()
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
end
