defmodule EWallet.Web.V1.TransactionOverlay do
  @moduledoc """
  Overlay for the Transaction schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    AccountOverlay,
    UserOverlay,
    WalletOverlay,
    TokenOverlay
  }

  def serializer, do: EWallet.Web.V1.TransactionSerializer

  def preload_assocs, do: default_preload_assocs()

  def default_preload_assocs,
    do: [
      :from_token,
      :from_wallet,
      :from_account,
      :from_user,
      :to_token,
      :to_wallet,
      :to_account,
      :to_user,
      :exchange_account,
      :exchange_wallet,
      exchange_pair: [
        :from_token,
        :to_token
      ]
    ]

  def search_fields,
    do: [
      :id,
      :idempotency_token,
      :status,
      :from,
      :to
    ]

  def sort_fields,
    do: [
      :id,
      :status,
      :from,
      :to,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :idempotency_token,
      :local_ledger_uuid,
      :error_code,
      :error_description,
      :status,
      :type,
      :calculated_at,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      idempotency_token: nil,
      local_ledger_uuid: nil,
      error_code: nil,
      error_description: nil,
      status: nil,
      type: nil,
      calculated_at: nil,
      inserted_at: nil,
      updated_at: nil,
      # From
      from_amount: nil,
      from_token: TokenOverlay.self_filter_fields(),
      from_wallet: WalletOverlay.self_filter_fields(),
      from_account: AccountOverlay.self_filter_fields(),
      from_user: UserOverlay.self_filter_fields(),
      # To
      to_amount: nil,
      to_token: TokenOverlay.self_filter_fields(),
      to_wallet: WalletOverlay.self_filter_fields(),
      to_account: AccountOverlay.self_filter_fields(),
      to_user: UserOverlay.self_filter_fields(),
      # Exchange
      exchange_account: AccountOverlay.self_filter_fields(),
      exchange_wallet: WalletOverlay.self_filter_fields()
    ]
end
