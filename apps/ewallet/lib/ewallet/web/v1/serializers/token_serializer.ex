defmodule EWallet.Web.V1.TokenSerializer do
  @moduledoc """
  Serializes token(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWallet.Web.{Date, Paginator}
  alias EWalletDB.Token

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(tokens) when is_list(tokens) do
    Enum.map(tokens, &serialize/1)
  end

  def serialize(%Token{} = token) do
    %{
      object: "token",
      id: token.id,
      symbol: token.symbol,
      name: token.name,
      subunit_to_unit: token.subunit_to_unit,
      metadata: token.metadata || %{},
      encrypted_metadata: token.encrypted_metadata || %{},
      created_at: Date.to_iso8601(token.inserted_at),
      updated_at: Date.to_iso8601(token.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
