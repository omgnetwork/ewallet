defmodule KuberaAdmin.V1.UserSerializer do
  @moduledoc """
  Serializes user data into V1 JSON response format.
  """

  def to_json(user) do
    %{
      object: "user",
      id: user.id,
      username: user.username,
      provider_user_id: user.provider_user_id,
      email: user.email,
      metadata: user.metadata
    }
  end
end
