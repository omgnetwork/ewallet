defmodule AdminAPI.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """
  alias AdminAPI.V1.PaginatorSerializer
  alias EWallet.Web.{Paginator, Date}

  def to_json(%Paginator{} = paginator) do
    PaginatorSerializer.to_json(paginator, &to_json/1)
  end
  def to_json(account) when is_map(account) do
    %{
      object: "account",
      id: account.id,
      name: account.name,
      description: account.description,
      master: account.master,
      created_at: Date.to_iso8601(account.inserted_at),
      updated_at: Date.to_iso8601(account.updated_at)
    }
  end
end
