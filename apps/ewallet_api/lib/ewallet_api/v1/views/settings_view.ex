defmodule EWalletAPI.V1.SettingsView do
  use EWalletAPI, :view
  use EWalletAPI.V1
  alias EWalletAPI.V1.{SettingsSerializer, ResponseSerializer}

  def render("settings.json", settings) do
    settings
    |> SettingsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
