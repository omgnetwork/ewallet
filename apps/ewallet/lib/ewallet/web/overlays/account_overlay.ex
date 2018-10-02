defmodule EWallet.Web.AccountOverlay do
  alias EWalletDB.Category
  
  def preload_assocs, do: [
    categories: Category
  ]

  def search_fields, do: [
    :id,
    :name,
    :description
  ]

  def sort_fields, do: [
    :id,
    :name,
    :description,
    :inserted_at,
    :updated_at
  ]
end
