defmodule EWallet.Web.V1.CategorySerializer do
  @moduledoc """
  Serializes categories into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.{AccountSerializer, PaginatorSerializer}
  alias EWalletDB.Category

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
    %{
      object: "category",
      id: category.id,
      name: category.name,
      description: category.description,
      account_ids: AccountSerializer.serialize(category.accounts, :id),
      accounts: AccountSerializer.serialize(category.accounts),
      created_at: Date.to_iso8601(category.inserted_at),
      updated_at: Date.to_iso8601(category.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(categories, :id) when is_list(categories) do
    Enum.map(categories, fn category -> category.id end)
  end

  def serialize(%NotLoaded{}, _), do: nil
  def serialize(nil, _), do: nil
end
