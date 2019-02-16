# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.APIKeyOverlay do
  @moduledoc """
  Overlay for the APIKey schema.
  """

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
