defmodule AdminAPI.V1.ConfigurationView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ConfigSettingSerializer, ResponseSerializer}

  def render("settings.json", settings) do
    settings
    |> ConfigSettingSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
