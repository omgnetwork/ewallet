defmodule EWalletAPI.V1.UserView do
  use EWalletAPI, :view
  use EWalletAPI.V1
  alias EWalletAPI.V1.{UserSerializer, ResponseSerializer}

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
