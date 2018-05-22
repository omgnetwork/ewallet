defmodule EWallet.Web.V1.SettingsSerializer do
  @moduledoc """
  Serializes provider settings data into V1 JSON response format.
  """
  alias EWallet.Web.V1.TokenSerializer

  def serialize(%{tokens: tokens}) do
    %{
      object: "setting",
      tokens: TokenSerializer.serialize(tokens)
    }
  end
end
