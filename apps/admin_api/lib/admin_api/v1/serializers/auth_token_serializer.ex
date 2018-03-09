defmodule AdminAPI.V1.AuthTokenSerializer do
  @moduledoc """
  Serializes authentication token data into V1 response format.
  """
  def serialize(%{auth_token: _, user: _} = attrs) do
    %{
      object: "authentication_token",
      authentication_token: attrs.auth_token,
      user_id: attrs.user.id,
    }
  end
end
