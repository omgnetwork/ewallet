defmodule KuberaAPI.V1.JSON.UserSettingsSerializer do
  @moduledoc """
  Serializes user settings data into V1 JSON response format.
  """
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.MintedTokenSerializer

  def serialize(%{minted_tokens: minted_tokens}) do
    %{
      object: "setting",
      minted_tokens: MintedTokenSerializer.serialize(minted_tokens)
    }
  end
end
