defmodule EWalletAPI.V1.JSON.TransactionSerializer do
  @moduledoc """
  Serializes minted token(s) into V1 JSON response format.
  """
  alias EWalletAPI.V1.JSON.{PaginatorSerializer, MintedTokenSerializer}
  alias EWallet.Web.{Date, Paginator}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end
  def serialize(transaction) when is_map(transaction) do
    %{
      object: "transaction",
      id: transaction.id,
      idempotency_token: transaction.idempotency_token,
      amount: transaction.amount,
      minted_token: MintedTokenSerializer.serialize(transaction.minted_token),
      from: transaction.from,
      to: transaction.to,
      status: transaction.status,
      created_at: Date.to_iso8601(transaction.inserted_at),
      updated_at: Date.to_iso8601(transaction.updated_at)
    }
  end
end
