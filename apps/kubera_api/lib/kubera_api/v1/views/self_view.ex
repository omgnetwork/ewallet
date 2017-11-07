defmodule KuberaAPI.V1.SelfView do
  use KuberaAPI, :view
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.{UserSerializer, UserSettingsSerializer,
    ResponseSerializer}

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("settings.json", settings) do
    settings
    |> UserSettingsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
