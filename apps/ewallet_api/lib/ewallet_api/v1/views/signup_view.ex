defmodule EWalletAPI.V1.SignupView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, UserSerializer}

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
