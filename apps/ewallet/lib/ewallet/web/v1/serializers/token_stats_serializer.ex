defmodule EWallet.Web.V1.TokenStatsSerializer do
  @moduledoc """
  Serializes token(s) into V1 JSON response format.
  """

  def serialize(nil), do: nil

  def serialize(stats) do
    %{
      object: "token_stats",
      token_id: stats.token_id,
      subunit_to_unit: stats.subunit_to_unit,
      total_supply: stats.total_supply
    }
  end
end
