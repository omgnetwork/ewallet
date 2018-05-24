defmodule EWalletAPI.V1.UserSettingsSerializer do
  @moduledoc """
  Serializes user settings data into V1 JSON response format.
  """
  alias EWallet.Web.V1.TokenSerializer

  def serialize(%{tokens: tokens}) do
    %{
      object: "setting",
      tokens: TokenSerializer.serialize(tokens)
    }
  end
end
