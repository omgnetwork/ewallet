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
  alias EWallet.PermissionsHelper
  alias EWalletDB.GlobalRole
  alias Utils.Intersecter

  def can?(actor, attrs) do
    check_permissions(
      Map.merge(attrs, %{
        actor: actor,
        role: Map.get(actor, :global_role) || GlobalRole.none(),
        permissions: GlobalRole.global_role_permissions()
      })
    )
  end

  defp check_permissions(%{permissions: permissions, role: role, action: :all, type: type}) do
    account_permissions =
      PermissionsHelper.extract_permission(permissions, [role, :account_permissions])

    permissions
    |> PermissionsHelper.extract_permission([role, type, :all])
    |> case do
      :global -> {true, account_permissions}
      :accounts -> {true, account_permissions}
      :self -> {true, account_permissions}
      _ -> {false, account_permissions}
    end
  end

  defp check_permissions(%{action: _, type: _, target: _} = attrs) do
    check_global_role(attrs)
  end

  defp check_permissions(%{action: _, target: target} = attrs) do
    check_global_role(Map.merge(attrs, %{type: PermissionsHelper.get_target_type(target)}))
  end

  defp check_permissions(_), do: {false, false}

  defp check_global_role(%{
         permissions: permissions,
         actor: actor,
         role: role,
         type: type,
         action: action,
         target: target
       }) do
    permissions
    |> PermissionsHelper.extract_permission([role, type, action])
    |> case do
      :global ->
        {true, true}

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

        {can, permissions[role][:account_permissions]}

      :self ->
        can =
          target
          |> PermissionsHelper.get_owner_uuids()
          |> Enum.member?(actor.uuid)

        {can, permissions[role][:account_permissions]}

      _ ->
        {false, permissions[role][:account_permissions]}
    end
  end
end
