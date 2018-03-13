defmodule EWalletAPI.V1.UserView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.ResponseSerializer
  alias EWalletAPI.V1.UserSerializer

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
