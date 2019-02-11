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

defmodule EWallet.GlobalPermissions do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWallet.{PermissionsHelper, Permission}
  alias EWalletDB.GlobalRole
  alias Utils.Intersecter

  def can(permission) do
    permission
    |> Map.put(:global_role, permission.actor.global_role || GlobalRole.none())
    |> check_permissions(GlobalRole.global_role_permissions())
  end

  defp check_permissions(%{global_role: role, action: :all, type: type} = permission, permissions) do
    permission = set_check_account_permissions(permission, permissions)

    permissions
    |> PermissionsHelper.extract_permission([role, type, :all])
    |> case do
      :global -> %{permission | global_authorized: true, global_permission: :global}
      :accounts -> %{permission | global_authorized: true, global_permission: :accounts}
      :self -> %{permission | global_authorized: true, global_permission: :self}
      p -> %{permission | global_authorized: false, global_permission: p}
    end
  end

  defp check_permissions(%{action: _, type: _, target: _} = permission, permissions) do
    check_global_role(permission, permissions)
  end

  defp check_permissions(%{action: _, target: target} = permission, permissions) do
    check_global_role(
      %{permission | type: PermissionsHelper.get_target_type(target)},
      permissions
    )
  end

  defp check_permissions(permission, _) do
    %{
      permission
      | global_authorized: false,
        global_permission: nil,
        check_account_permissions: false
    }
  end

  defp check_global_role(
         %{
           actor: actor,
           global_role: role,
           type: type,
           action: action,
           target: target
         } = permission,
         permissions
       ) do
    permissions
    |> PermissionsHelper.extract_permission([role, type, action])
    |> case do
      :global ->
        %{permission | global_authorized: true, global_permission: :global}

      :accounts ->
        # 1. Get all accounts where user have appropriate role
        # 2. Get all accounts that have rights on the target
        # 3. Check if we have any matches!
        target_accounts = PermissionsHelper.get_target_accounts(target)

        can =
          actor
          |> PermissionsHelper.get_actor_accounts()
          |> Intersecter.intersect(target_accounts)
          |> length()
          |> Kernel.>(0)

        %{
          permission
          | global_authorized: can,
            global_permission: :accounts,
            check_account_permissions: permissions[role][:account_permissions]
        }

      :self ->
        can =
          target
          |> PermissionsHelper.get_owner_uuids()
          |> Enum.member?(actor.uuid)

        %{
          permission
          | global_authorized: can,
            global_permission: :self,
            check_account_permissions: permissions[role][:account_permissions]
        }

      p ->
        %{
          permission
          | global_authorized: false,
            global_permission: p,
            check_account_permissions: permissions[role][:account_permissions]
        }
    end
  end

  defp set_check_account_permissions(%Permission{global_role: role} = permission, permissions) do
    ap = PermissionsHelper.extract_permission(permissions, [role, :account_permissions])
    %{permission | check_account_permissions: ap}
  end
end
