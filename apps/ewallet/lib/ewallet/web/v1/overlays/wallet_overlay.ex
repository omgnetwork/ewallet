defmodule EWallet.Web.V1.WalletOverlay do
  @moduledoc """
  Overlay for the Wallet schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    UserOverlay,
    AccountOverlay
  }

  def preload_assocs,
    do: [
      :user,
      :account
    ]

  def default_preload_assocs,
    do: [
      :user,
      :account
    ]

  def search_fields,
    do: [
      :address,
      :name,
      :identifier
    ]

  def sort_fields,
    do: [
      :address,
      :name,
      :identifier,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :address,
      :name,
      :identifier,
      :enabled,
      :inserted_at,
      :created_at
    ]

  def filter_fields,
    do: [
      address: nil,
      name: nil,
      identifier: nil,
      enabled: nil,
      inserted_at: nil,
      created_at: nil,
      user: UserOverlay.self_filter_fields(),
      account: AccountOverlay.self_filter_fields()
    ]
end
