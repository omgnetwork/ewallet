defmodule AdminAPI.V1.SelfView do
  use AdminAPI, :view
  alias AdminAPI.V1.UserSerializer
  alias EWallet.Web.V1.ResponseSerializer

  @doc """
  Renders a user response with the given user.
  """
  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
