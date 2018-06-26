defmodule EWallet.Web.V1.TransactionSerializer do
  @moduledoc """
  Serializes token(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{PaginatorSerializer, TokenSerializer}
  alias EWallet.Web.{Date, Paginator}
  alias EWalletDB.Transaction
  alias EWalletDB.Helpers.{Assoc, Preloader}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%Transaction{} = transaction) do
    transaction = Preloader.preload(transaction, [:from_token, :to_token])

    # credo:disable-for-next-line
    %{
      object: "transaction",
      id: transaction.id,
      idempotency_token: transaction.idempotency_token,
      from: %{
        object: "transaction_source",
        address: transaction.from,
        amount: transaction.from_amount,
        token_id: Assoc.get(transaction, [:from_token, :id]),
        token: TokenSerializer.serialize(transaction.from_token)
      },
      to: %{
        object: "transaction_source",
        address: transaction.to,
        amount: transaction.to_amount,
        token_id: Assoc.get(transaction, [:to_token, :id]),
        token: TokenSerializer.serialize(transaction.to_token)
      },
      exchange: %{
        object: "exchange",
        rate: 1
      },
      metadata: transaction.metadata || %{},
      encrypted_metadata: transaction.encrypted_metadata || %{},
      status: transaction.status,
      created_at: Date.to_iso8601(transaction.inserted_at),
      updated_at: Date.to_iso8601(transaction.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
