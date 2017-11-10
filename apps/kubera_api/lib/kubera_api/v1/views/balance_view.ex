defmodule KuberaAPI.V1.BalanceView do
  use KuberaAPI, :view
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.{AddressSerializer, ListSerializer,
                           ResponseSerializer}

  def render("balances.json", %{addresses: addresses}) do
    addresses
    |> Enum.map(&AddressSerializer.serialize/1)
    |> ListSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
