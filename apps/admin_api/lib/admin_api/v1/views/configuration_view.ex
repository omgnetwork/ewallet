defmodule AdminAPI.V1.ConfigurationView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ConfigSettingSerializer, ResponseSerializer}

  def render("settings.json", %{settings: settings}) do
    settings
    |> ConfigSettingSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("settings_with_errors.json", %{settings: settings}) do
    settings
    |> ConfigSettingSerializer.serialize_with_errors()
    |> ResponseSerializer.serialize(success: true)
  end
end
