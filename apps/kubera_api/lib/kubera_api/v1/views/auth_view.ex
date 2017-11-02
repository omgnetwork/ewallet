defmodule KuberaAPI.V1.AuthView do
  use KuberaAPI, :view
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.{AuthTokenSerializer, ResponseSerializer}

  def render("auth_token.json", %{auth_token: auth_token}) do
    auth_token
    |> AuthTokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
