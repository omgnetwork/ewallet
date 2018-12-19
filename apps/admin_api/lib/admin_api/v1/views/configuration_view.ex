defmodule AdminAPI.V1.ConfigurationView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ConfigurationSerializer, ResponseSerializer}

  def render("settings.json", %{settings: settings}) do
    settings
    |> ConfigurationSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("settings_with_errors.json", %{settings: settings}) do
    settings
    |> ConfigurationSerializer.serialize_with_errors()
    |> ResponseSerializer.serialize(success: true)
  end
end
