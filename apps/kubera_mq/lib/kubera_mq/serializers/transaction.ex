defmodule KuberaMQ.Serializers.Transaction do
  @moduledoc """
  Format a transaction the way Caishen expects it.
  """
  def serialize(transfer) do
    %{
      metadata: transfer.metadata,
      minted_token: %{
        friendly_id: transfer.minted_token.friendly_id,
        metadata: transfer.minted_token.metadata
      },
      debits: [%{
        address: transfer.from_balance.address,
        amount: transfer.amount,
        metadata: transfer.from_balance.metadata
      }],
      credits: [%{
        address: transfer.to_balance.address,
        amount: transfer.amount,
        metadata: transfer.to_balance.metadata
      }]
    }
  end
end
