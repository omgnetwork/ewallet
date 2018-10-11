defmodule EWallet.Web.V1.KeyOverlay do
  @moduledoc """
  Overlay for the Key schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.AccountOverlay

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
      :access_key
    ]

  def sort_fields,
    do: [
      :access_key,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :access_key,
      :expired,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def filter_fields,
    do: [
      access_key: nil,
      expired: nil,
      inserted_at: nil,
      updated_at: nil,
      deleted_at: nil,
      account: AccountOverlay.self_filter_fields()
    ]
end
