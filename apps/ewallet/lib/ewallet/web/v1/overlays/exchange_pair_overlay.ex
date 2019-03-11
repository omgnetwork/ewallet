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

defmodule EWallet.Web.V1.ExchangePairOverlay do
  @moduledoc """
  Overlay for the ExchangePair schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.TokenOverlay

  def preload_assocs,
    do: [
      :from_token,
      :to_token
    ]

  def default_preload_assocs,
    do: [
      :from_token,
      :to_token
    ]

  def search_fields,
    do: [
      :id
    ]

  def sort_fields,
    do: [
      :id,
      :rate,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :rate,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def filter_fields,
    do: [
      id: nil,
      rate: nil,
      inserted_at: nil,
      updated_at: nil,
      deleted_at: nil,
      from_token: TokenOverlay.self_filter_fields(),
      to_token: TokenOverlay.self_filter_fields()
    ]

  def pagination_fields,
    do: [
      :id,
      :inserted_at,
      :updated_at
    ]
end
