defmodule EWalletAPI.V1.AuthTokenSerializer do
  @moduledoc """
  Serializes auth token data into V1 JSON response format.
  """
  use EWalletAPI.V1

  def serialize(auth_token) do
    %{
      object: "authentication_token",
      authentication_token: auth_token
    }
  end
end
