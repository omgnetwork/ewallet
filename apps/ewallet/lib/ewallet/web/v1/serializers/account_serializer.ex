defmodule EWallet.Web.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator, AccountOverlay, SerializerHelper}
  alias EWallet.Web.V1.{CategorySerializer, PaginatorSerializer}
  alias EWalletDB.Account
  alias EWalletDB.Helpers.Assoc
  alias EWalletDB.Uploaders.Avatar

  def serialize(records, caller_schema \\ nil)

  def serialize(%Paginator{} = paginator, _caller_schema) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(accounts, caller_schema) when is_list(accounts) do
    %{
      object: "list",
      data: Enum.map(accounts, fn account ->
        serialize(account, caller_schema)
      end)
    }
  end

  def serialize(%Account{} = account, caller_schema) do
    SerializerHelper.ensure_preloaded(account, AccountOverlay, caller_schema)

    %{
      object: "account",
      id: account.id,
      socket_topic: "account:#{account.id}",
      parent_id: Assoc.get(account, [:parent, :id]),
      name: account.name,
      description: account.description,
      master: Account.master?(account),
      category_ids: CategorySerializer.serialize_ids(account.categories),
      categories: CategorySerializer.serialize(account.categories),
      avatar: Avatar.urls({account.avatar, account}),
      metadata: account.metadata || %{},
      encrypted_metadata: account.encrypted_metadata || %{},
      created_at: Date.to_iso8601(account.inserted_at),
      updated_at: Date.to_iso8601(account.updated_at)
    }
  end

  def serialize(%NotLoaded{}, _), do: nil
  def serialize(nil, _), do: nil

  def serialize_ids(accounts) when is_list(accounts) do
    Enum.map(accounts, fn account -> account.id end)
  end
  #
  # def serialize_ids(%NotLoaded{}), do: nil
  # def serialize_ids(nil), do: nil
end
