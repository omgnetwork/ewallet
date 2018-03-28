defmodule EWallet.Web.V1.AddressSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.BalanceSerializer

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
  def serialize(address) do
    %{
      object: "address",
      socket_topic: "address:#{address.address}",
      balances: serialize_balances(address.balances),
      address: address.address,
    }
  end

  defp serialize_balances(balances) do
    Enum.map(balances, &BalanceSerializer.serialize/1)
  end
end
