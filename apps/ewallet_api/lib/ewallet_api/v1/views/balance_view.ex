defmodule EWalletAPI.V1.BalanceView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{AddressSerializer, ListSerializer, ResponseSerializer}

  def render("balances.json", %{addresses: addresses}) do
    addresses
    |> Enum.map(&AddressSerializer.serialize/1)
    |> ListSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
