defmodule EWallet.Web.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWallet.Web.{Paginator, Date}
  alias EWalletDB.Account
  alias EWalletDB.Uploaders.Avatar

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end
  def serialize(accounts) when is_list(accounts) do
    %{
      object: "list",
      data: Enum.map(accounts, &serialize/1)
    }
  end
  def serialize(account) when is_map(account) do
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
  def serialize(nil) do
    nil
  end
end
