defmodule AdminAPI.V1.SelfView do
  use AdminAPI, :view
  alias AdminAPI.V1.{UserSerializer, ResponseSerializer}

  @doc """
  Renders a user response with the given user.
  """
  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
