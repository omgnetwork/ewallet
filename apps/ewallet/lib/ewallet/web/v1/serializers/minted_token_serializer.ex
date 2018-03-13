defmodule EWallet.Web.V1.MintedTokenSerializer do
  @moduledoc """
  Serializes minted token(s) into V1 JSON response format.
  """
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWallet.Web.{Date, Paginator}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end
  def serialize(minted_tokens) when is_list(minted_tokens),
    do: Enum.map(minted_tokens, &serialize/1)
  def serialize(minted_token) when is_map(minted_token) do
    %{
      object: "minted_token",
      id: minted_token.friendly_id,
      symbol: minted_token.symbol,
      name: minted_token.name,
      subunit_to_unit: minted_token.subunit_to_unit,
      metadata: minted_token.metadata,
      encrypted_metadata: minted_token.encrypted_metadata,
      created_at: Date.to_iso8601(minted_token.inserted_at),
      updated_at: Date.to_iso8601(minted_token.updated_at)
    }
  end
end
