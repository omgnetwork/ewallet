defmodule EWallet.Web.V1.WalletSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.BalanceSerializer

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(wallet) do
    %{
      object: "wallet",
      socket_topic: "wallet:#{wallet.address}",
      balances: serialize_balances(wallet.balances),
      address: wallet.address
    }
  end

  defp serialize_balances(balances) do
    Enum.map(balances, &BalanceSerializer.serialize/1)
  end
end
