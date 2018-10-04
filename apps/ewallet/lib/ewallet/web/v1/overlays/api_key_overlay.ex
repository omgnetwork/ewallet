defmodule EWallet.Web.V1.APIKeyOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs,
    do: [
      :account
    ]

  def default_preload_assocs,
    do: [
      :account
    ]

  def search_fields,
    do: [
      :id,
      :key
    ]

  def sort_fields,
    do: [
      :id,
      :key,
      :owner_app,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields, do: []
  def filter_fields, do: []
end
