defmodule EWallet.Web.V1.AddressSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.BalanceSerializer

  def serialize(address) when is_map(address) do
    %{
      object: "address",
      balances: serialize_balances(address.balances),
      address: address.address,
    }
  end
  def serialize(%NotLoaded{}), do: nil

  defp serialize_balances(balances) do
    Enum.map(balances, &BalanceSerializer.serialize/1)
  end
end
