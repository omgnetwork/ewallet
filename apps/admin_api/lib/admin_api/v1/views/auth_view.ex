defmodule AdminAPI.V1.AuthView do
  use AdminAPI, :view
  alias AdminAPI.V1.{ResponseSerializer, AuthTokenSerializer}

  def render("auth_token.json", attrs) do
    attrs
    |> AuthTokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty_response.json", _attrs) do
    ResponseSerializer.serialize(%{}, success: true)
  end
end
