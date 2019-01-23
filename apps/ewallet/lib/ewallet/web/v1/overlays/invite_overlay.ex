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

defmodule EWallet.Web.V1.InviteOverlay do
  @moduledoc """
  Overlay for the Invite schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    UserOverlay
  }

  def preload_assocs,
    do: [:user]

  def default_preload_assocs,
    do: [:user]

  def sort_fields,
    do: [
      :id,
      :token,
      :verified_at,
      :inserted_at,
      :updated_at
    ]

  def search_fields,
    do: [:id, :token]

  def self_filter_fields,
    do: [
      :id,
      :token,
      :success_url,
      :verified_at,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      token: nil,
      success_url: nil,
      verified_at: nil,
      inserted_at: nil,
      updated_at: nil,
      user: UserOverlay.default_preload_assocs()
    ]

  def pagination_fields,
    do: [:id]
end
