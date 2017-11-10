defmodule KuberaAPI.V1.JSON.AddressSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.BalanceSerializer

  def serialize(address) do
    %{
      object: "address",
      balances: serialize_balances(address.balances),
      address: address.address,
    }
  end

  defp serialize_balances(balances) do
    Enum.map(balances, &BalanceSerializer.serialize/1)
  end
end
