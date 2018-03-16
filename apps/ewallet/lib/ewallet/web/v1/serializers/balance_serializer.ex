defmodule EWallet.Web.V1.BalanceSerializer do
  @moduledoc """
  Serializes balance data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.MintedTokenSerializer

  # Both the given balance and `%NotLoaded{}` are maps
  # so we need to pattern-match `%NotLoaded{}` first.
  def serialize(%NotLoaded{}), do: nil
  def serialize(balance) when is_map(balance) do
    %{
      object: "balance",
      minted_token: MintedTokenSerializer.serialize(balance.minted_token),
      amount: balance.amount
    }
  end
  def serialize(nil), do: nil
end
