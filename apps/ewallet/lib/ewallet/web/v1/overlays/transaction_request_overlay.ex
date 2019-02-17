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

defmodule EWallet.Web.V1.TransactionRequestOverlay do
  @moduledoc """
  Overlay for the TransactionRequest schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    TransactionConsumptionOverlay,
    UserOverlay,
    AccountOverlay,
    TokenOverlay,
    WalletOverlay,
    AccountOverlay,
    WalletOverlay
  }

  def preload_assocs,
    do: [
      :account,
      :token,
      :user,
      :exchange_account,
      :exchange_wallet
    ]

  def default_preload_assocs,
    do: [
      :account,
      :token,
      :user,
      :exchange_account,
      :exchange_wallet
    ]

  def search_fields,
    do: [
      :id,
      :status,
      :type,
      :correlation_id,
      :expiration_reason
    ]

  def sort_fields,
    do: [
      :id,
      :status,
      :type,
      :correlation_id,
      :inserted_at,
      :expired_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :type,
      :amount,
      :status,
      :correlation_id,
      :require_confirmation,
      :max_consumptions,
      :max_consumptions_per_user,
      :consumption_lifetime,
      :expiration_date,
      :expired_at,
      :inserted_at,
      :updated_at,
      :expiration_reason,
      :allow_amount_override
    ]

  def filter_fields,
    do: [
      :id,
      :type,
      :amount,
      :status,
      :correlation_id,
      :require_confirmation,
      :max_consumptions,
      :max_consumptions_per_user,
      :consumption_lifetime,
      :expiration_date,
      :expired_at,
      :inserted_at,
      :updated_at,
      :expiration_reason,
      :allow_amount_override,
      consumptions: TransactionConsumptionOverlay.self_filter_fields(),
      user: UserOverlay.self_filter_fields(),
      account: AccountOverlay.self_filter_fields(),
      token: TokenOverlay.self_filter_fields(),
      wallet: WalletOverlay.self_filter_fields(),
      exchange_account: AccountOverlay.self_filter_fields(),
      exchange_wallet: WalletOverlay.self_filter_fields()
    ]
end
