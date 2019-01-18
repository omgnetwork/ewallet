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

defmodule EWallet.Web.V1.UserOverlay do
  @moduledoc """
  Overlay for the User schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    InviteOverlay,
    WalletOverlay,
    AuthTokenOverlay,
    MembershipOverlay,
    RoleOverlay,
    AccountOverlay
  }

  def page_record_fields(),
    do: [:id]

  def preload_assocs,
    do: []

  def default_preload_assocs,
    do: [:wallets]

  def sort_fields,
    do: [
      :id,
      :username,
      :email,
      :full_name,
      :calling_name,
      :provider_user_id,
      :inserted_at,
      :updated_at
    ]

  def search_fields,
    do: [
      :id,
      :username,
      :email,
      :full_name,
      :calling_name,
      :provider_user_id
    ]

  def self_filter_fields,
    do: [
      :id,
      :username,
      :email,
      :full_name,
      :calling_name,
      :provider_user_id,
      :inserted_at,
      :created_at
    ]

  def filter_fields,
    do: [
      id: nil,
      username: nil,
      email: nil,
      provider_user_id: nil,
      inserted_at: nil,
      created_at: nil,
      invite: InviteOverlay.default_preload_assocs(),
      wallets: WalletOverlay.default_preload_assocs(),
      auth_tokens: AuthTokenOverlay.default_preload_assocs(),
      memberships: MembershipOverlay.default_preload_assocs(),
      roles: RoleOverlay.default_preload_assocs(),
      accounts: AccountOverlay.default_preload_assocs()
    ]
end
