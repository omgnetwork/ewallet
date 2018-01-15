defmodule KuberaAdmin.V1.UserView do
  use KuberaAdmin, :view
  alias KuberaAdmin.V1.{ResponseSerializer, UserSerializer}

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
