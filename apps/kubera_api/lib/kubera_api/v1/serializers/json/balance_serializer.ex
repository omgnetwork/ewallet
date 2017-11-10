defmodule KuberaAPI.V1.JSON.BalanceSerializer do
  @moduledoc """
  Serializes balance data into V1 JSON response format.
  """
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.MintedTokenSerializer

  def serialize(balance) do
    %{
      object: "balance",
      minted_token: MintedTokenSerializer.serialize(balance.minted_token),
      amount: balance.amount
    }
  end
end
