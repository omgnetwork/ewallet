defmodule AdminAPI.V1.UserAuthView do
  use AdminAPI, :view
  alias EWallet.Web.V1.ResponseSerializer
  alias EWallet.Web.V1.UserAuthTokenSerializer

  def render("auth_token.json", %{auth_token: auth_token}) do
    auth_token
    |> UserAuthTokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty_response.json", _attrs) do
    %{}
    |> ResponseSerializer.serialize(success: true)
  end
end
