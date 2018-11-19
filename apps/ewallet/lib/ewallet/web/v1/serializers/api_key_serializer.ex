defmodule EWallet.Web.V1.APIKeySerializer do
  @moduledoc """
  Serializes API key(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWalletDB.APIKey

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%APIKey{} = api_key) do
    %{
      object: "api_key",
      id: api_key.id,
      key: api_key.key,
      account_id: api_key.account.id,
      owner_app: api_key.owner_app,
      # To remove when deprecated
      expired: !api_key.enabled,
      enabled: api_key.enabled,
      created_at: Date.to_iso8601(api_key.inserted_at),
      updated_at: Date.to_iso8601(api_key.updated_at),
      deleted_at: Date.to_iso8601(api_key.deleted_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
