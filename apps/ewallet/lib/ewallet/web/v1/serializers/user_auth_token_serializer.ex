defmodule EWallet.Web.V1.UserAuthTokenSerializer do
  @moduledoc """
  Serializes auth token data into V1 JSON response format.
  """

  def serialize(auth_token) do
    %{
      object: "authentication_token",
      authentication_token: auth_token.token
    }
  end
end
