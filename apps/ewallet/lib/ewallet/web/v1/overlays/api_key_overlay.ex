defmodule EWallet.Web.V1.APIKeyOverlay do
  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    AccountOverlay,
    WalletOverlay
  }

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
      :key,
      :owner_app
    ]

  def sort_fields,
    do: [
      :id,
      :key,
      :owner_app,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :key,
      :owner_app,
      :expired,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def filter_fields,
    do: [
      id: nil,
      key: nil,
      owner_app: nil,
      expired: nil,
      inserted_at: nil,
      updated_at: nil,
      deleted_at: nil,
      account: AccountOverlay.self_filter_fields(),
      exchange_wallet: WalletOverlay.self_filter_fields()
    ]
end
