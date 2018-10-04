defmodule EWallet.Web.V1.CategoryOverlay do
  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.AccountOverlay

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

  def self_filter_fields,
    do: [
      :id,
      :name,
      :description,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def filter_fields,
    do: [
      id: nil,
      name: nil,
      description: nil,
      inserted_at: nil,
      updated_at: nil,
      deleted_at: nil,
      accounts: AccountOverlay.self_filter_fields()
    ]
end
