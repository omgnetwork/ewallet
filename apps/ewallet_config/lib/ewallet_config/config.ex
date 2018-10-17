defmodule EWalletConfig.Config do
  alias EWalletConfig.{FileStorageSettingsLoader, EmailSettingsLoader, Setting}

  def load(app, name, opts \\ nil)
  def load(app, :file_storage, _opts) do
    FileStorageSettingsLoader.load(app)
  end

  def load(app, :emails, %{mailer: mailer}) do
    EmailSettingsLoader.load(app, mailer)
  end

  def get(key) do
    Setting.get(key)
  end
end
