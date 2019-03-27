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

defmodule EWallet.Web.V1.APIKeyOverlay do
  @moduledoc """
  Overlay for the APIKey schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    KeyOverlay,
    UserOverlay
  }

  def preload_assocs,
    do: [
      :creator_user,
      :creator_key
    ]

  def default_preload_assocs,
    do: [
      :creator_user,
      :creator_key
    ]

  def search_fields,
    do: [
      :id,
      :key,
      :name
    ]

  def sort_fields,
    do: [
      :id,
      :key,
      :name,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :key,
      :name,
      :expired,
      :inserted_at,
      :updated_at,
      :deleted_at
    ]

  def filter_fields,
    do: [
      id: nil,
      key: nil,
      name: nil,
      expired: nil,
      inserted_at: nil,
      updated_at: nil,
      deleted_at: nil,
      creator_user: UserOverlay.self_filter_fields(),
      creator_key: KeyOverlay.self_filter_fields()
    ]

  def pagination_fields,
    do: [
      :id,
      :inserted_at,
      :updated_at
    ]
end
