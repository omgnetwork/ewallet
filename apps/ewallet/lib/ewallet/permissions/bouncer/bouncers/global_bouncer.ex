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

defmodule EWallet.Bouncer.GlobalBouncer do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWallet.Bouncer.{Dispatcher, Helper, Permission}
  alias EWalletDB.GlobalRole
  alias Utils.Intersecter

  def bounce(permission, config) do
    permission
    |> Map.put(:global_role, permission.actor.global_role || GlobalRole.none())
    |> check_permissions(config)
  end

  defp check_permissions(%{action: :all} = permission, config) do
    check_scope_permissions(permission, config)
  end

  defp check_permissions(%{action: :export} = permission, config) do
    check_scope_permissions(permission, config)
  end

  defp check_permissions(%{action: _, type: nil, target: target} = permission, config) do
    check_global_role(
      %{permission | type: Dispatcher.get_target_type(target)},
      config
    )
  end

  defp check_permissions(%{action: _, type: _, target: _} = permission, config) do
    check_global_role(permission, config)
  end

  defp check_permissions(permission, _) do
    %{
      permission
      | global_authorized: false,
        global_abilities: nil,
        check_account_permissions: false
    }
  end

  defp check_scope_permissions(
         %{global_role: role, action: action, schema: schema} = permission,
         config
       ) do
    types = Dispatcher.get_target_types(schema, config.dispatch_config)
    permission = set_check_account_permissions(permission, config.global_permissions)

    abilities =
      Enum.into(types, %{}, fn type ->
        {type, Helper.extract_permission(config.global_permissions, [role, types, action]) || :none}
      end)

    account_permissions = check_account_permissions(config.global_permissions, role)

    permission = %{
      permission
      | global_abilities: abilities,
        check_account_permissions: account_permissions
    }

    %{
      permission
      | global_authorized:
          Enum.any?(abilities, fn {_, ability} ->
            Enum.member?([:global, :accounts, :self], ability)
          end)
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
         config
       ) do
    config.global_permissions
    |> Helper.extract_permission([role, type, action])
    |> case do
      :global ->
        %{permission | global_authorized: true, global_abilities: %{type => :global}}

      :accounts ->
        target_accounts = Dispatcher.get_target_accounts(target, config.dispatch_config)

        can =
          actor
          |> Dispatcher.get_actor_accounts(config.dispatch_config)
          |> Intersecter.intersect(target_accounts)
          |> length()
          |> Kernel.>(0)

        %{
          permission
          | global_authorized: can,
            global_abilities: %{type => :accounts},
            check_account_permissions: config.global_permissions[role][:account_permissions]
        }

      :self ->
        can =
          target
          |> Dispatcher.get_owner_uuids(config.dispatch_config)
          |> Enum.member?(actor.uuid)

        %{
          permission
          | global_authorized: can,
            global_abilities: %{type => :self},
            check_account_permissions: config.global_permissions[role][:account_permissions]
        }

      _ ->
        %{
          permission
          | global_authorized: false,
            global_abilities: %{type => :none},
            check_account_permissions: config.global_permissions[GlobalRole.none()][:account_permissions]
        }
    end
  end

    defp check_account_permissions(permissions, role) do
    case is_map(permissions[role]) do
      true ->
        permissions[role][:account_permissions]

      false ->
        false
    end
  end

  defp set_check_account_permissions(%Permission{global_role: role} = permission, permissions) do
    ap = Helper.extract_permission(permissions, [role, :account_abilities])
    %{permission | check_account_permissions: ap}
  end
end
