defmodule KuberaAdmin.V1.AuthView do
  use KuberaAdmin, :view
  alias KuberaAdmin.V1.{ResponseSerializer, AuthTokenSerializer}

  def render("auth_token.json", attrs) do
    attrs
    |> AuthTokenSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end

  def render("empty_response.json", _attrs) do
    ResponseSerializer.to_json(%{}, success: true)
  end
end
