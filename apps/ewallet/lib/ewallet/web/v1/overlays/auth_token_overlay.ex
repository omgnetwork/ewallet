defmodule EWallet.Web.V1.AuthTokenOverlay do
  alias EWalletDB.Category

  def preload_assocs,
    do: [
      categories: Category
    ]

  def search_fields,
    do: [
      :id,
      :name,
      :description
    ]

  def sort_fields,
    do: [
      :id,
      :name,
      :description,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields, do: []
  def filter_fields, do: []
end
