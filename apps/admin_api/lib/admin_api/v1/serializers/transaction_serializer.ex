defmodule AdminAPI.V1.TransactionSerializer do
  @moduledoc """
  Serializes minted token(s) into V1 JSON response format.
  """
  alias AdminAPI.V1.{PaginatorSerializer, MintedTokenSerializer}
  alias EWallet.Web.{Date, Paginator}

  def to_json(%Paginator{} = paginator) do
    PaginatorSerializer.to_json(paginator, &to_json/1)
  end
  def to_json(transaction) when is_map(transaction) do
    %{
      object: "transaction",
      id: transaction.id,
      idempotency_token: transaction.idempotency_token,
      amount: transaction.amount,
      minted_token: MintedTokenSerializer.to_json(transaction.minted_token),
      from: transaction.from,
      to: transaction.to,
      status: transaction.status,
      created_at: Date.to_iso8601(transaction.inserted_at),
      updated_at: Date.to_iso8601(transaction.updated_at)
    }
  end
end
