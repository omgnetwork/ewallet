defmodule EWallet.Web.V1.TransactionConsumptionOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs, do: default_preload_assocs()

  def default_preload_assocs,
    do: [
      :account,
      :user,
      :wallet,
      :token,
      :exchange_account,
      :account,
      :exchange_account,
      transaction: [
        :from_token,
        :to_token,
        :exchange_pair,
        :to_wallet,
        :from_wallet,
        :from_account,
        :to_account,
        :from_user,
        :to_user,
        :exchange_account,
        :exchange_wallet,
        :from_account,
        :to_account,
        exchange_account: []
      ],
      transaction_request: [
        :consumptions,
        :token,
        :user,
        :exchange_wallet,
        :account,
        :exchange_account
      ]
    ]

  def search_fields,
    do: [
      :id,
      :status,
      :correlation_id,
      :idempotency_token
    ]

  def sort_fields,
    do: [
      :id,
      :status,
      :correlation_id,
      :idempotency_token,
      :inserted_at,
      :updated_at,
      :approved_at,
      :rejected_at,
      :confirmed_at,
      :failed_at,
      :expired_at
    ]

  def self_filter_fields, do: []

  def filter_fields, do: []
end
