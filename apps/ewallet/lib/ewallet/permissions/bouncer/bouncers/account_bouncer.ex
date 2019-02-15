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

defmodule EWallet.Bouncer.AccountBouncer do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWallet.Bouncer.{Dispatcher, Helper}
  alias EWalletDB.{Membership, Role}
  alias Utils.Intersecter

  def bounce(permission) do
    check_permissions(permission, Role.account_role_permissions())
  end

  defp check_permissions(%{actor: actor, action: :all, schema: schema} = permission, permissions) do
    types = Dispatcher.get_target_types(schema)
    uuids = actor |> Dispatcher.get_actor_accounts() |> Helper.get_uuids()
    memberships = Membership.query_all_by_member_and_account_uuids(actor, uuids, [:role])

    find_sufficient_permission_in_memberships(permission, permissions, memberships, types)
  end

  defp check_permissions(%{action: _, target: target, type: nil} = permission, permissions) do
    permission = %{permission | type: Dispatcher.get_target_type(target)}
    check_account_role(permission, permissions)
  end

  defp check_permissions(%{action: _, type: _, target: _} = permission, permissions) do
    check_account_role(permission, permissions)
  end

  defp check_account_role(
         %{
           actor: actor,
           type: type,
           target: target
         } = permission,
         permissions
       ) do
    actor_account_uuids = actor |> Dispatcher.get_actor_accounts() |> Helper.get_uuids()

    target_account_uuids = target |> Dispatcher.get_target_accounts() |> Helper.get_uuids()

    case Intersecter.intersect(actor_account_uuids, target_account_uuids) do
      [] ->
        %{permission | account_authorized: false}

      matched_account_uuids ->
        memberships =
          Membership.query_all_by_member_and_account_uuids(actor, matched_account_uuids, [:role])

        find_sufficient_permission_in_memberships(permission, permissions, memberships, [type])
    end
  end

  defp find_sufficient_permission_in_memberships(
         permission,
         permissions,
         [membership | memberships],
         types
       ) do
    permission
    |> update_abilities(membership.role.name, types, permissions)
    |> find_sufficient_permission_in_memberships(permissions, memberships, types)
  end

  defp find_sufficient_permission_in_memberships(
         permission,
         permissions,
         [membership | []],
         types
       ) do
    permission
    |> update_abilities(membership.role.name, types, permissions)
    |> set_account_authorized()
  end

  defp find_sufficient_permission_in_memberships(permission, _, _, _) do
    set_account_authorized(permission)
  end

  defp set_account_authorized(permission) do
    %{permission | account_authorized: account_authorized?(permission)}
  end

  defp account_authorized?(%{account_abilities: account_abilities}) do
    Enum.any?(account_abilities, fn {type, ability} ->
      Enum.member?([:global, :accounts, :self], ability)
    end)
  end

  defp update_abilities(%{action: action} = permission, role, types, permissions) do
    Enum.reduce(types, permission, fn type, permission ->
      new_ability = Helper.extract_permission(permissions, [role, type, action]) || :none

      case get_best_ability(permission.account_abilities[type], new_ability) do
        {:changed, ability} ->
          abilities = Map.put(permission.account_abilities, type, ability)
          %{permission | account_abilities: abilities}

        {:identical, _} ->
          permission
      end
    end)
  end

  defp get_best_ability(nil, nil), do: {:identical, nil}
  defp get_best_ability(old, new) when old == new, do: {:identical, old}

  defp get_best_ability(:global, :accounts), do: {:identical, :global}
  defp get_best_ability(:global, :self), do: {:identical, :global}

  defp get_best_ability(:accounts, :global), do: {:changed, :global}
  defp get_best_ability(:accounts, :self), do: {:identical, :accounts}

  defp get_best_ability(:self, :global), do: {:changed, :global}
  defp get_best_ability(:self, :accounts), do: {:changed, :accounts}

  defp get_best_ability(old, nil), do: {:identical, old}
  defp get_best_ability(nil, new), do: {:changed, new}
end
