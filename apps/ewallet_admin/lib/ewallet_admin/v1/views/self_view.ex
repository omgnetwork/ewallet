defmodule EWalletAdmin.V1.SelfView do
  use EWalletAdmin, :view
  alias EWalletAdmin.V1.{UserSerializer, ResponseSerializer}

  @doc """
  Renders a user response with the given user.
  """
  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
