defmodule EWallet.Web.V1.MintSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}

  alias EWallet.Web.V1.{
    AccountSerializer,
    PaginatorSerializer,
    TokenSerializer,
    TransactionSerializer
  }

  alias Utils.Helpers.Assoc
  alias EWalletDB.Mint

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(mints) when is_list(mints) do
    Enum.map(mints, &serialize/1)
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%Mint{} = mint) do
    %{
      object: "mint",
      id: mint.id,
      description: mint.description,
      amount: mint.amount,
      confirmed: mint.confirmed,
      token_id: Assoc.get(mint, [:token, :id]),
      token: TokenSerializer.serialize(mint.token),
      account_id: Assoc.get(mint, [:account, :id]),
      account: AccountSerializer.serialize(mint.account),
      transaction_id: Assoc.get(mint, [:transaction, :id]),
      transaction: TransactionSerializer.serialize(mint.transaction),
      created_at: Date.to_iso8601(mint.inserted_at),
      updated_at: Date.to_iso8601(mint.updated_at)
    }
  end
end
