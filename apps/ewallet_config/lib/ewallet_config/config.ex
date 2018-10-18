defmodule EWalletConfig.Config do
  use GenServer
  require Logger
  alias EWalletConfig.{FileStorageSettingsLoader, EmailSettingsLoader, Setting}

  def start_link(registered_apps \\ []) do
    GenServer.start_link(__MODULE__, registered_apps, name: __MODULE__)
  end

  def init(_args) do
    {:ok, []}
  end

  def register_and_load(app, settings) do
    GenServer.call(__MODULE__, {:register_and_load, app, settings})
  end

  def reload_config do
    GenServer.call(__MODULE__, :reload)
  end

  def handle_call({:register_and_load, app, settings}, _from, registered_apps) do
    load_settings(app, settings)
    {:reply, :ok, [{app, settings} | registered_apps]}
  end

  def handle_call(:reload, _from, registered_apps) do
    Enum.each(registered_apps, fn {app, settings} ->
      load_settings(app, settings)
    end)

    {:reply, :ok, registered_apps}
  end

  def load_settings(app, settings) do
    Enum.each(settings, fn key ->
      case Setting.get(key) do
        nil ->
          if Mix.env != :test, do: warn(app, key)
          Application.put_env(app, key, nil)
        setting ->
          Application.put_env(app, key, setting.value)
      end
    end)
  end

  def warn(app, key) do
    Logger.warn(~s([Configuration] Setting "#{key}" used by "#{app}" not found.))
  end

  def load(app, name, opts \\ nil)
  def load(app, :file_storage, _opts) do
    ensure_settings_existence()
    FileStorageSettingsLoader.load(app)
  end

  def load(app, :emails, %{mailer: mailer}) do
    ensure_settings_existence()
    EmailSettingsLoader.load(app, mailer)
  end

  def settings do
    Setting.all()
  end

  def get(key) do
    Setting.get_value(key)
  end

  def get_default_settings, do: Setting.get_default_settings()

  def insert_all_defaults(opts \\ %{}) do
    :ok = Setting.insert_all_defaults(opts)
    reload_config()
  end

  def insert(attrs), do: Setting.insert(attrs)
  def update(key, attrs), do: Setting.update(key, attrs)

  defp ensure_settings_existence do
    unless Mix.env == :test || length(Setting.all()) > 0 do
      raise ~s(Setting seeds have not been ran. You can run them with "mix seed" or "mix seed --settings".)
    end
  end
end
