defmodule AdminAPI.V1.WalletView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, WalletSerializer}

  def render("wallet.json", %{wallet: wallet}) do
    wallet
    |> WalletSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("wallets.json", %{wallets: wallets}) do
    wallets
    |> WalletSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
