defmodule EWalletAdmin.V1.MintedTokenView do
  use EWalletAdmin, :view
  alias EWalletAdmin.V1.{ResponseSerializer, MintedTokenSerializer}

  def render("minted_token.json", %{minted_token: minted_token}) do
    minted_token
    |> MintedTokenSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("minted_tokens.json", %{minted_tokens: minted_tokens}) do
    minted_tokens
    |> MintedTokenSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
