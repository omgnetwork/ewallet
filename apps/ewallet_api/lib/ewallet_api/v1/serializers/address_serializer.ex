defmodule EWalletAPI.V1.AddressSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  use EWalletAPI.V1
  alias EWalletAPI.V1.BalanceSerializer

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
