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

defmodule EWallet.Web.V1.TokenOverlay do
  @moduledoc """
  Overlay for the Token schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.AccountOverlay

  def pagination_fields,
    do: [:id]

  def preload_assocs,
    do: [
      :account
    ]

  def default_preload_assocs, do: []

  def search_fields,
    do: [
      :id,
      :symbol,
      :name
    ]

  def sort_fields,
    do: [
      :id,
      :symbol,
      :name,
      :subunit_to_unit,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :symbol,
      :iso_code,
      :name,
      :description,
      :short_symbol,
      :subunit,
      :subunit_to_unit,
      :symbol_first,
      :html_entity,
      :iso_numeric,
      :smallest_denomination,
      :locked,
      :enabled,
      :inserted_at,
      :created_at
    ]

  def filter_fields,
    do: [
      id: nil,
      symbol: nil,
      iso_code: nil,
      name: nil,
      description: nil,
      short_symbol: nil,
      subunit: nil,
      subunit_to_unit: nil,
      symbol_first: nil,
      html_entity: nil,
      iso_numeric: nil,
      smallest_denomination: nil,
      locked: nil,
      enabled: nil,
      inserted_at: nil,
      created_at: nil,
      account: AccountOverlay.default_preload_assocs()
    ]
end
