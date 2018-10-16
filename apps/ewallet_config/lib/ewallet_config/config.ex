defmodule EWalletConfig.Config do
  alias EWalletConfig.{FileStorageSettingsLoader, Setting}

  def load(app, :file_storage) do
    FileStorageSettingsLoader.load(app)
  end

  def get(key) do
    Setting.get_value(key)
  end
end
