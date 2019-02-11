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

defmodule EWallet.AccountPermissions do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWallet.PermissionsHelper
  alias EWalletDB.{Membership, Role}
  alias Utils.Intersecter

  def can(permission) do
    check_permissions(permission, Role.account_role_permissions())
  end

  defp check_permissions(%{actor: actor, action: :all} = permission, permissions) do
    uuids = actor |> PermissionsHelper.get_actor_accounts() |> PermissionsHelper.get_uuids()
    memberships = Membership.query_all_by_member_and_account_uuids(actor, uuids, [:role])

    find_sufficient_permission_in_memberships(permission, permissions, memberships)
  end

  defp check_permissions(%{action: _, target: target, type: nil} = permission, permissions) do
    permission = %{permission | type: PermissionsHelper.get_target_type(target)}
    check_account_role(permission, permissions)
  end

  defp check_permissions(%{action: _, type: _, target: _} = permission, permissions) do
    check_account_role(permission, permissions)
  end

  defp check_account_role(
         %{
           actor: actor,
           target: target
         } = permission,
         permissions
       ) do
    actor_account_uuids =
      actor |> PermissionsHelper.get_actor_accounts() |> PermissionsHelper.get_uuids()

    target_account_uuids =
      target |> PermissionsHelper.get_target_accounts() |> PermissionsHelper.get_uuids()

    case Intersecter.intersect(actor_account_uuids, target_account_uuids) do
      [] ->
        %{permission | account_authorized: false}

      matched_account_uuids ->
        handle_matched_accounts(permission, permissions, matched_account_uuids)
    end
  end

  def handle_matched_accounts(
        %{
          actor: actor
        } = permission,
        permissions,
        matched_account_uuids
      ) do
    memberships =
      Membership.query_all_by_member_and_account_uuids(actor, matched_account_uuids, [:role])

    find_sufficient_permission_in_memberships(permission, permissions, memberships)
  end

  defp find_sufficient_permission_in_memberships(
         %{type: type, action: action} = permission,
         permissions,
         [membership | memberships]
       ) do
    permissions
    |> PermissionsHelper.extract_permission([membership.role.name, type, action])
    |> find_sufficient_permission(permission, permissions, memberships)
  end

  defp find_sufficient_permission(:global, permission, _, _) do
    %{permission | account_authorized: true, account_permission: :global}
  end

  defp find_sufficient_permission(:accounts, permission, _, _) do
    %{permission | account_authorized: true, account_permission: :accounts}
  end

  defp find_sufficient_permission(:self, permission, _, _) do
    %{permission | account_authorized: true, account_permission: :self}
  end

  defp find_sufficient_permission(_, permission, permissions, memberships) do
    find_sufficient_permission_in_memberships(permission, permissions, memberships)
  end
end
