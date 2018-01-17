defmodule EWalletAPI.V1.JSON.BalanceSerializer do
  @moduledoc """
  Serializes balance data into V1 JSON response format.
  """
  use EWalletAPI.V1
  alias EWalletAPI.V1.JSON.MintedTokenSerializer

  def serialize(balance) do
    %{
      object: "balance",
      minted_token: MintedTokenSerializer.serialize(balance.minted_token),
      amount: balance.amount
    }
  end
end
