defmodule AdminAPI.V1.MintView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, MintSerializer}

  def render("mint.json", %{mint: mint}) do
    mint
    |> MintSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("mints.json", %{mints: mints}) do
    mints
    |> MintSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
