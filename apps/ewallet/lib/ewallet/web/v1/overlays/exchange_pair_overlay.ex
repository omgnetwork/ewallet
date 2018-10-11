defmodule EWallet.Web.V1.ExchangePairOverlay do
  @moduledoc """
  Overlay for the ExchangePair schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.TokenOverlay

  def preload_assocs,
    do: [
      :from_token,
      :to_token
    ]

  def default_preload_assocs,
    do: [
      :from_token,
      :to_token
    ]

  def search_fields,
    do: [
      :id
    ]

  def sort_fields,
    do: [
      :id,
      :rate,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :rate,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def filter_fields,
    do: [
      id: nil,
      rate: nil,
      inserted_at: nil,
      updated_at: nil,
      deleted_at: nil,
      from_token: TokenOverlay.self_filter_fields(),
      to_token: TokenOverlay.self_filter_fields()
    ]
end
