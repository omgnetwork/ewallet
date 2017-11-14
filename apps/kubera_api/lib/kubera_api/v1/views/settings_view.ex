defmodule KuberaAPI.V1.SettingsView do
  use KuberaAPI, :view
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.{SettingsSerializer, ResponseSerializer}

  def render("settings.json", settings) do
    settings
    |> SettingsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
