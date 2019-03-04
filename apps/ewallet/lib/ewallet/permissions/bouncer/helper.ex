# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.Bouncer.Helper do
  @moduledoc """
  Helper functions for Bouncer.
  """
  import Ecto.Query
  alias EWalletDB.{User, Key, Membership, AccountUser}

  # Cleans up dirty inputs into a unified actor representation.
  # Either a key, an admin user or an end user
  def get_actor(%{admin_user: admin_user}), do: admin_user
  def get_actor(%{end_user: end_user}), do: end_user
  def get_actor(%{key: key}), do: key
  def get_actor(%{originator: %{end_user: end_user}}), do: end_user
  def get_actor(_), do: nil

  def get_uuids(list) do
    Enum.map(list, fn account -> account.uuid end)
  end

  def extract_permission(%{} = subset, [next_key | next_keys]) do
    extract_permission(subset[next_key], next_keys)
  end

  def extract_permission(permission, _) do
    permission
  end

  def prepare_query_with_membership_for(actor, query, type \\ :inner)

  def prepare_query_with_membership_for(%User{is_admin: true} = user, query, type) do
    join(query, type, [g], m in Membership, on: m.user_uuid == ^user.uuid)
  end

  def prepare_query_with_membership_for(%User{is_admin: false} = user, query, type) do
    join(query, type, [g], m in AccountUser, on: m.user_uuid == ^user.uuid)
  end

  def prepare_query_with_membership_for(%Key{} = key, query, type) do
    join(query, type, [g], m in Membership, on: m.key_uuid == ^key.uuid)
  end
end
