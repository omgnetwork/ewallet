defmodule EWallet.Web.V1.TokenOverlay do
  @moduledoc """
  Overlay for the Token schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.AccountOverlay

  def preload_assocs, do: [
    :account
  ]

  def default_preload_assocs, do: []

  def search_fields, do: [
    :id,
    :symbol,
    :name
  ]

  def sort_fields, do: [
    :id,
    :symbol,
    :name,
    :subunit_to_unit,
    :inserted_at,
    :updated_at
  ]

  def self_filter_fields, do: [
    :id,
    :symbol,
    :iso_code,
    :name,
    :description,
    :short_symbol,
    :subunit,
    :subunit_to_unit,
    :symbol_first,
    :html_entity,
    :iso_numeric,
    :smallest_denomination,
    :locked,
    :enabled,
    :inserted_at,
    :created_at
  ]

  def filter_fields, do: [
    id: nil,
    symbol: nil,
    iso_code: nil,
    name: nil,
    description: nil,
    short_symbol: nil,
    subunit: nil,
    subunit_to_unit: nil,
    symbol_first: nil,
    html_entity: nil,
    iso_numeric: nil,
    smallest_denomination: nil,
    locked: nil,
    enabled: nil,
    inserted_at: nil,
    created_at: nil,
    account: AccountOverlay.default_preload_assocs()
  ]
end
