# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.Web.V1.TransactionConsumptionOverlay do
  @moduledoc """
  Overlay for the TransactionConsumption schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    TransactionOverlay,
    ExchangePairOverlay,
    UserOverlay,
    AccountOverlay,
    TransactionRequestOverlay,
    TokenOverlay,
    WalletOverlay,
    AccountOverlay,
    WalletOverlay
  }

  def page_record_fields,
    do: [:id]

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
        exchange_pair: [
          :to_token,
          :from_token
        ],
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

  def self_filter_fields,
    do: [
      :id,
      :amount,
      :estimated_consumption_amount,
      :estimated_request_amount,
      :estimated_rate,
      :correlation_id,
      :idempotency_token,
      :status,
      :approved_at,
      :rejected_at,
      :confirmed_at,
      :failed_at,
      :expired_at,
      :estimated_at,
      :error_code,
      :error_description,
      :expiration_date
    ]

  def filter_fields,
    do: [
      :id,
      :amount,
      :estimated_consumption_amount,
      :estimated_request_amount,
      :estimated_rate,
      :correlation_id,
      :idempotency_token,
      :status,
      :approved_at,
      :rejected_at,
      :confirmed_at,
      :failed_at,
      :expired_at,
      :estimated_at,
      :error_code,
      :error_description,
      :expiration_date,
      transaction: TransactionOverlay.self_filter_fields(),
      exchange_pair: ExchangePairOverlay.self_filter_fields(),
      user: UserOverlay.self_filter_fields(),
      account: AccountOverlay.self_filter_fields(),
      transaction_request: TransactionRequestOverlay.self_filter_fields(),
      token: TokenOverlay.self_filter_fields(),
      wallet: WalletOverlay.self_filter_fields(),
      exchange_account: AccountOverlay.self_filter_fields(),
      exchange_wallet: WalletOverlay.self_filter_fields()
    ]
end
