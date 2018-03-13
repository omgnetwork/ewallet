defmodule EWalletAPI.V1.UserSerializer do
  @moduledoc """
  Serializes user data into V1 JSON response format.
  """

  def serialize(user) do
    %{
      object: "user",
      id: user.id,
      username: user.username,
      provider_user_id: user.provider_user_id,
      metadata: user.metadata,
      encrypted_metadata: user.encrypted_metadata
    }
  end
end
