defmodule EWallet.Web.V1.KeySerializer do
  @moduledoc """
  Serializes key(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWallet.Web.{Date, Paginator}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end
  def serialize(%NotLoaded{}), do: nil
  def serialize(key) when is_map(key) do
    %{
      object: "key",
      id: key.id,
      access_key: key.access_key,
      secret_key: key.secret_key,
      account_id: key.account_id,
      created_at: Date.to_iso8601(key.inserted_at),
      updated_at: Date.to_iso8601(key.updated_at),
      deleted_at: Date.to_iso8601(key.deleted_at)
    }
  end
end
