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

defmodule EWallet.Web.V1.AccountOverlay do
  @moduledoc """
  Overlay for the Account schema.
  """
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

  def pagination_fields,
    do: [
      :id,
      :inserted_at,
      :updated_at
    ]
end
