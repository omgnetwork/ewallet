defmodule EWalletAPI.V1.WalletView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{WalletSerializer, ListSerializer, ResponseSerializer}

  def render("wallets.json", %{wallets: wallets}) do
    wallets
    # |> Enum.map(&WalletSerializer.serialize/1)
    |> WalletSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
