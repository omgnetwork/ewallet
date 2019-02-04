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

  def can?(actor, attrs) do
    check_permissions(
      Map.merge(attrs, %{
        actor: actor,
        permissions: Role.account_role_permissions()
      })
    )
  end

  defp check_permissions(%{action: _, type: _, target: _} = attrs) do
    check_account_role(attrs)
  end

  defp check_permissions(%{actor: actor, permissions: permissions, action: :all, type: type}) do
    uuids = actor |> PermissionsHelper.get_actor_accounts() |> PermissionsHelper.get_uuids()
    memberships = Membership.query_all_by_member_and_account_uuids(actor, uuids)

    Enum.any?(memberships, fn membership ->
      case permissions[membership.role][type][:all] do
        :global -> true
        :accounts -> true
        :self -> true
        _ -> false
      end
    end)
  end

  defp check_permissions(%{action: _, target: target} = attrs) do
    check_account_role(Map.merge(attrs, %{type: PermissionsHelper.get_target_type(target)}))
  end

  defp check_account_role(%{
         actor: actor,
         target: target
       } = attrs) do
    actor_account_uuids =
      actor |> PermissionsHelper.get_actor_accounts() |> PermissionsHelper.get_uuids()

    target_account_uuids =
      target |> PermissionsHelper.get_target_accounts() |> PermissionsHelper.get_uuids()

    # IO.inspect(actor)
    # IO.inspect(type)
    # IO.inspect(action)
    # IO.inspect(target)

    case Intersecter.intersect(actor_account_uuids, target_account_uuids) do
      [] ->
        false

      matched_account_uuids ->
        handle_matched_accounts(attrs, actor, matched_account_uuids)
    end
  end

  def handle_matched_accounts(%{
    permissions: permissions,
    actor: actor,
    type: type,
    action: action
  }, actor, matched_account_uuids) do
    memberships =
      Membership.query_all_by_member_and_account_uuids(actor, matched_account_uuids, [:role])

    Enum.any?(memberships, fn membership ->
      case permissions[membership.role.name][type][action] do
        :global ->
          true

        :accounts ->
          true

        _ ->
          false
      end
    end)
  end
end
