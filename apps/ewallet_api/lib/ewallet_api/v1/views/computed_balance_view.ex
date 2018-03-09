defmodule EWalletAPI.V1.ComputedBalanceView do
  use EWalletAPI, :view
  use EWalletAPI.V1
  alias EWalletAPI.V1.{AddressSerializer, ListSerializer,
                           ResponseSerializer}

  def render("balances.json", %{addresses: addresses}) do
    addresses
    |> Enum.map(&AddressSerializer.serialize/1)
    |> ListSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
