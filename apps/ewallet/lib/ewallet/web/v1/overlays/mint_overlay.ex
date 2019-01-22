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

defmodule EWallet.Web.V1.MintOverlay do
  @moduledoc """
  Overlay for the Mint schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{AccountOverlay, TokenOverlay, TransactionOverlay}

  def page_record_fields,
    do: [:id]

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
