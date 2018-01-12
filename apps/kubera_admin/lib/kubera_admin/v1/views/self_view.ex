defmodule KuberaAdmin.V1.SelfView do
  use KuberaAdmin, :view
  alias KuberaAdmin.V1.{UserSerializer, ResponseSerializer}

  @doc """
  Renders a user response with the given user.
  """
  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
