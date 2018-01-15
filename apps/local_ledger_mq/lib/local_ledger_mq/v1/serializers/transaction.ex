defmodule LocalLedgerMQ.V1.Serializers.Transaction do
  @moduledoc """
  Transaction serializer used for formatting.
  """
  def serialize(transaction) do
    %{
      object: "transaction",
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      minted_token_friendly_id: transaction.minted_token_friendly_id,
      balance_address: transaction.balance_address,
      inserted_at: transaction.inserted_at
    }
  end
end
