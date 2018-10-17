defmodule EWalletConfig.Config do
  alias EWalletConfig.{FileStorageSettingsLoader, EmailSettingsLoader, Setting}

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
    Setting.get(key)
  end

  def get_default_settings, do: Setting.get_default_settings()
  def insert_all_defaults(opts \\ %{}), do: Setting.insert_all_defaults(opts)
  def insert(attrs), do: Setting.insert(attrs)
  def update(key, attrs), do: Setting.update(key, attrs)

  defp ensure_settings_existence do
    unless Mix.env == :test || length(Setting.all()) > 0 do
      raise ~s(Setting seeds have not been ran. You can run them with "mix seed" or "mix seed --settings".)
    end
  end
end
