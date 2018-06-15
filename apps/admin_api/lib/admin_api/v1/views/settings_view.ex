defmodule AdminAPI.V1.SettingsView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, SettingsSerializer}

  def render("settings.json", settings) do
    settings
    |> SettingsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
