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
      id: nil,
      type: nil,
      amount: nil,
      status: nil,
      correlation_id: nil,
      require_confirmation: nil,
      max_consumptions: nil,
      max_consumptions_per_user: nil,
      consumption_lifetime: nil,
      expiration_date: nil,
      expired_at: :datetime,
      inserted_at: :datetime,
      updated_at: :datetime,
      expiration_reason: nil,
      allow_amount_override: nil
    ]

  def filter_fields,
    do: [
      id: nil,
      type: nil,
      amount: nil,
      status: nil,
      correlation_id: nil,
      require_confirmation: nil,
      max_consumptions: nil,
      max_consumptions_per_user: nil,
      consumption_lifetime: nil,
      expiration_date: nil,
      expired_at: :datetime,
      inserted_at: :datetime,
      updated_at: :datetime,
      expiration_reason: nil,
      allow_amount_override: nil,
      consumptions: TransactionConsumptionOverlay.self_filter_fields(),
      user: UserOverlay.self_filter_fields(),
      account: AccountOverlay.self_filter_fields(),
      token: TokenOverlay.self_filter_fields(),
      wallet: WalletOverlay.self_filter_fields(),
      exchange_account: AccountOverlay.self_filter_fields(),
      exchange_wallet: WalletOverlay.self_filter_fields()
    ]

  def pagination_fields,
    do: [
      :id,
      :inserted_at,
      :updated_at
    ]
end
