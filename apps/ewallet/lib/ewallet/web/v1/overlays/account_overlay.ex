defmodule EWallet.Web.V1.AccountOverlay do
  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    CategoryOverlay,
    WalletOverlay,
    TokenOverlay,
    KeyOverlay,
    APIKeyOverlay,
    MembershipOverlay
  }

  def preload_assocs,
    do: [
      :parent,
      :categories
    ]

  def default_preload_assocs,
    do: [
      :parent,
      :categories
    ]

  def sort_fields,
    do: [
      :id,
      :name,
      :description,
      :inserted_at,
      :updated_at
    ]

  def search_fields,
    do: [
      :id,
      :name,
      :description
    ]

  def self_filter_fields,
    do: [
      :id,
      :name,
      :description,
      :inserted_at,
      :updated_at,
      :metadata
    ]

  def filter_fields,
    do: [
      id: nil,
      name: nil,
      description: nil,
      inserted_at: nil,
      updated_at: nil,
      metadata: nil,
      parent: self_filter_fields(),
      categories: CategoryOverlay.self_filter_fields(),
      wallets: WalletOverlay.self_filter_fields(),
      tokens: TokenOverlay.self_filter_fields(),
      keys: KeyOverlay.self_filter_fields(),
      api_keys: APIKeyOverlay.self_filter_fields(),
      memberships: MembershipOverlay.self_filter_fields()
    ]
end
