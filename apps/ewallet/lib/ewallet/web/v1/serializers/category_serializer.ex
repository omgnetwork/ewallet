defmodule EWallet.Web.V1.CategorySerializer do
  @moduledoc """
  Serializes categories into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWallet.Web.{Paginator, Date}
  alias EWalletDB.Category
  alias EWalletDB.Helpers.Preloader

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(categories) when is_list(categories) do
    %{
      object: "list",
      data: Enum.map(categories, &serialize/1)
    }
  end

  def serialize(%Category{} = category) do
    category = Preloader.preload(category, [:accounts])

    %{
      object: "category",
      id: category.id,
      name: category.name,
      description: category.description,
      account_ids: Enum.map(category.accounts, fn(account) -> account.id end),
      accounts: category.categories,
      created_at: Date.to_iso8601(category.inserted_at),
      updated_at: Date.to_iso8601(category.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
