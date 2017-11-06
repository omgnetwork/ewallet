defmodule KuberaMQ.Serializers.Transaction do
  @moduledoc """
  Format a transaction the way Caishen expects it.
  """
  def serialize(%{
    from: from,
    to: to,
    minted_token: minted_token,
    amount: amount,
    metadata: metadata
  }) do
    %{
      metadata: metadata,
      minted_token: %{
        symbol: minted_token.symbol,
        metadata: minted_token.metadata
      },
      debits: [%{
        address: from.address,
        amount: amount,
        metadata: from.metadata
      }],
      credits: [%{
        address: to.address,
        amount: amount,
        metadata: to.metadata
      }]
    }
  end
end
