defmodule EWallet.Web.V1.TokenStatsSerializer do
  @moduledoc """
  Serializes token(s) into V1 JSON response format.
  """
  alias EWallet.Web.V1.TokenSerializer

  def serialize(nil), do: nil

  def serialize(stats) do
    %{
      object: "token_stats",
      token_id: stats.token.id,
      token: TokenSerializer.serialize(stats.token),
      total_supply: stats.total_supply
    }
  end
end
