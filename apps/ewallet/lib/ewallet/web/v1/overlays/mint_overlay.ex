defmodule EWallet.Web.V1.MintOverlay do
  @moduledoc """
  Overlay for the Mint schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{AccountOverlay, TokenOverlay, TransactionOverlay}

  def preload_assocs,
    do: [
      :token,
      :account,
      :transaction
    ]

  def default_preload_assocs,
    do: [
      :token,
      :account,
      :transaction
    ]

  def search_fields,
    do: [
      :id,
      :description
    ]

  def sort_fields,
    do: [
      :id,
      :description,
      :amount,
      :confirmed,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :description,
      :amount,
      :confirmed,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      description: nil,
      amount: nil,
      confirmed: nil,
      inserted_at: nil,
      updated_at: nil,
      token: TokenOverlay.self_filter_fields(),
      account: AccountOverlay.self_filter_fields(),
      transaction: TransactionOverlay.self_filter_fields()
    ]
end
