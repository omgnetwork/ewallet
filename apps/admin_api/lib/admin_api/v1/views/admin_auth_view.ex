defmodule AdminAPI.V1.AdminAuthView do
  use AdminAPI, :view
  alias AdminAPI.V1.AuthTokenSerializer
  alias EWallet.Web.V1.ResponseSerializer

  def render("auth_token.json", %{auth_token: auth_token}) do
    auth_token
    |> AuthTokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty_response.json", _attrs) do
    ResponseSerializer.serialize(%{}, success: true)
  end
end
