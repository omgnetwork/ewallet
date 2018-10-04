defmodule EWallet.Web.V1.AccountOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs, do: [
    :parent,
    :categories
  ]

  def default_preload_assocs, do: [
    :parent,
    :categories
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
