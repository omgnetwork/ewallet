defmodule EWallet.Web.V1.CategoryOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs, do: [:accounts]

  def default_preload_assocs,
    do: [
      :accounts
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
