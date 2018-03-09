defmodule AdminAPI.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """
  alias AdminAPI.V1.PaginatorSerializer
  alias EWallet.Web.{Paginator, Date}
  alias EWalletDB.Account
  alias EWalletDB.Uploaders.Avatar

  def to_json(%Paginator{} = paginator) do
    PaginatorSerializer.to_json(paginator, &to_json/1)
  end
  def to_json(accounts) when is_list(accounts) do
    %{
      object: "list",
      data: Enum.map(accounts, &to_json/1)
    }
  end
  def to_json(account) when is_map(account) do
    %{
      object: "account",
      id: account.id,
      parent_id: account.parent_id,
      name: account.name,
      description: account.description,
      master: Account.master?(account),
      avatar: Avatar.urls({account.avatar, account}),
      metadata: account.metadata,
      encrypted_metadata: account.encrypted_metadata,
      created_at: Date.to_iso8601(account.inserted_at),
      updated_at: Date.to_iso8601(account.updated_at)
    }
  end
  def to_json(nil) do
    nil
  end
end
