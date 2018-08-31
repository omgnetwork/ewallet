defmodule AdminAPI.V1.UserView do
  use AdminAPI, :view
  alias EWallet.Web.V1.ResponseSerializer
  alias EWallet.Web.V1.UserSerializer

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("users.json", %{users: users}) do
    users
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
