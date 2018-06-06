defmodule AdminAPI.V1.TokenView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, TokenSerializer}

  def render("token.json", %{token: token}) do
    token
    |> TokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("tokens.json", %{tokens: tokens}) do
    tokens
    |> TokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("stats.json", %{stats: stats}) do
    stats
    |> TokenStatsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
