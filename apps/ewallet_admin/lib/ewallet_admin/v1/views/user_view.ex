defmodule EWalletAdmin.V1.UserView do
  use EWalletAdmin, :view
  alias EWalletAdmin.V1.{ResponseSerializer, UserSerializer}

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("users.json", %{users: users}) do
    users
    |> UserSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
