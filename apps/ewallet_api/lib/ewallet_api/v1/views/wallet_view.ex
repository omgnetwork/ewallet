defmodule EWalletAPI.V1.WalletView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, WalletSerializer}

  def render("wallets.json", %{wallets: wallets}) do
    wallets
    |> WalletSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
