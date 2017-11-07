defmodule KuberaAPI.V1.JSON.MintedTokenSerializer do
  @moduledoc """
  Serializes minted token data into V1 JSON response format.
  """
  use KuberaAPI.V1
  alias KuberaDB.MintedToken

  def serialize(minted_tokens) when is_list(minted_tokens),
    do: Enum.map(minted_tokens, &serialize/1)
  def serialize(%MintedToken{} = minted_token) do
    %{
      object: "minted_token",
      symbol: minted_token.symbol,
      name: minted_token.name,
      subunit_to_unit: minted_token.subunit_to_unit
    }
  end
end
