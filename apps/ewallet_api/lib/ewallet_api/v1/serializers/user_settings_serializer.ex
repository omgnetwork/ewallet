defmodule EWalletAPI.V1.UserSettingsSerializer do
  @moduledoc """
  Serializes user settings data into V1 JSON response format.
  """
  alias EWallet.Web.V1.MintedTokenSerializer

  def serialize(%{minted_tokens: minted_tokens}) do
    %{
      object: "setting",
      minted_tokens: MintedTokenSerializer.serialize(minted_tokens)
    }
  end
end
