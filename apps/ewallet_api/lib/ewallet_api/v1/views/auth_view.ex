defmodule EWalletAPI.V1.AuthView do
  use EWalletAPI, :view
  use EWalletAPI.V1
  alias EWalletAPI.V1.{AuthTokenSerializer, ResponseSerializer}

  def render("auth_token.json", %{auth_token: auth_token}) do
    auth_token
    |> AuthTokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty_response.json", _attrs) do
    %{}
    |> ResponseSerializer.serialize(success: true)
  end
end
