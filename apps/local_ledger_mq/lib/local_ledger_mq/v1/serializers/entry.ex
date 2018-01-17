defmodule LocalLedgerMQ.V1.Serializers.Entry do
  @moduledoc """
  Entry serializer used for formatting.
  """
  alias LocalLedgerMQ.V1.Serializers.Transaction

  def serialize(nil), do: %{}
  def serialize(entry) do
    %{
      object: "entry",
      id: entry.id,
      correlation_id: entry.correlation_id,
      metadata: entry.metadata,
      inserted_at: entry.inserted_at,
      transactions: serialize_transactions(entry.transactions)
    }
  end

  defp serialize_transactions(transactions) do
    Enum.map transactions, fn transaction ->
      Transaction.serialize(transaction)
    end
  end
end
