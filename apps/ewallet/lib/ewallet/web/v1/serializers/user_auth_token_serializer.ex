defmodule EWallet.Web.V1.UserAuthTokenSerializer do
  @moduledoc """
  Serializes auth token data into V1 JSON response format.
  """
  alias EWallet.Web.V1.UserSerializer
  alias Utils.Helpers.Assoc

  def serialize(auth_token) do
    %{
      object: "authentication_token",
      authentication_token: auth_token.token,
      user_id: Assoc.get(auth_token, [:user, :id]),
      user: UserSerializer.serialize(auth_token.user)
    }
  end
end
