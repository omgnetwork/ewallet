defmodule EWalletAPI.V1.AuthView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, UserSerializer, UserAuthTokenSerializer}

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

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
