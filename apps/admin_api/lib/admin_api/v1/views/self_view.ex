defmodule AdminAPI.V1.SelfView do
  use AdminAPI, :view
  alias EWallet.Web.V1.ResponseSerializer
  alias EWallet.Web.V1.UserSerializer

  @doc """
  Renders a user response with the given user.
  """
  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
