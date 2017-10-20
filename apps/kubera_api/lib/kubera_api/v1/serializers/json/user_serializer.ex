defmodule KuberaAPI.V1.JSON.UserSerializer do
  @moduledoc """
  Serializes user data into V1 JSON response format.
  """
  use KuberaAPI.V1

  def serialize(user) do
    %{
      object: "user",
      id: user.id,
      username: user.username,
      provider_user_id: user.provider_user_id,
      metadata: user.metadata
    }
  end
end
