defmodule EWallet.Web.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWallet.Web.{Paginator, Date}
  alias EWalletDB.Account
  alias EWalletDB.Helpers.{Assoc, Preloader}
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

  def serialize(%Account{} = account) do
    account = Preloader.preload(account, :parent)

    %{
      object: "account",
      id: account.id,
      socket_topic: "account:#{account.id}",
      parent_id: Assoc.get(account, [:parent, :id]),
      name: account.name,
      description: account.description,
      master: Account.master?(account),
      avatar: Avatar.urls({account.avatar, account}),
      metadata: account.metadata || %{},
      encrypted_metadata: account.encrypted_metadata || %{},
      created_at: Date.to_iso8601(account.inserted_at),
      updated_at: Date.to_iso8601(account.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
