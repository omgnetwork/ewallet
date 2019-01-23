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

defmodule EWallet.Web.V1.ExportOverlay do
  @moduledoc """
  Overlay for the Export schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    UserOverlay,
    KeyOverlay
  }

  def pagination_fields,
    do: [:id]

  def preload_assocs,
    do: [
      :user,
      :key
    ]

  def default_preload_assocs,
    do: [
      :user,
      :key
    ]

  def search_fields,
    do: [
      :id,
      :filename
    ]

  def sort_fields,
    do: [
      :id,
      :filename,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :schema,
      :status,
      :completion,
      :url,
      :filename,
      :path,
      :failure_reason,
      :estimated_size,
      :total_count,
      :adapter,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      schema: nil,
      status: nil,
      completion: nil,
      url: nil,
      filename: nil,
      path: nil,
      failure_reason: nil,
      estimated_size: nil,
      total_count: nil,
      adapter: nil,
      inserted_at: nil,
      updated_at: nil,
      user: UserOverlay.self_filter_fields(),
      key: KeyOverlay.self_filter_fields()
    ]
end
