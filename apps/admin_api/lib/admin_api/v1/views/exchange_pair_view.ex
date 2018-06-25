defmodule AdminAPI.V1.ExchangePairView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, ExchangePairSerializer}

  def render("exchange_pair.json", %{exchange_pair: exchange_pair}) do
    exchange_pair
    |> ExchangePairSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("exchange_pairs.json", %{exchange_pairs: exchange_pairs}) do
    exchange_pairs
    |> ExchangePairSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
