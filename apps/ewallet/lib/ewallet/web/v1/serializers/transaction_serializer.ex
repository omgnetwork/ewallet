defmodule EWallet.Web.V1.TransactionSerializer do
  @moduledoc """
  Serializes minted token(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{PaginatorSerializer, MintedTokenSerializer}
  alias EWallet.Web.{Date, Paginator}
  alias EWalletDB.Transfer

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end
  def serialize(%Transfer{} = transaction) do
    serialized_minted_token = MintedTokenSerializer.serialize(transaction.minted_token)

    # credo:disable-for-next-line
    %{
      object: "transaction",
      id: transaction.external_id,
      idempotency_token: transaction.idempotency_token,
      from: %{
        object: "transaction_source",
        address: transaction.from,
        amount: transaction.amount,
        minted_token: serialized_minted_token,
      },
      to: %{
        object: "transaction_source",
        address: transaction.to,
        amount: transaction.amount,
        minted_token: serialized_minted_token,
      },
      exchange: %{
        object: "exchange",
        rate: 1,
      },
      metadata: transaction.metadata,
      encrypted_metadata: transaction.encrypted_metadata,
      status: transaction.status,
      created_at: Date.to_iso8601(transaction.inserted_at),
      updated_at: Date.to_iso8601(transaction.updated_at)
    }
  end
  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
