# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.MembershipChecker do
  @moduledoc """
  Module responsible for checking if a user can be added to an account.
  """
  alias EWalletDB.{Account, Membership}

  @doc """
  Checks whether the given originator can add the user to the given account.

  Note that this function **does not check for the permission** to add a membership.
  Its purpose is to inform whether there is a conflicting membership with the given
  arguments or not.

  Returns `true` if the user can be added to the account
  without a conflicting existing membership.
  """
  def allowed?(user, account, role, originator) do
    memberships = Membership.all_by_user(user, [:role, :account])
    membership_accounts_uuids = load_uuids(memberships, :account_uuid)

    account
    |> init_search_ancestors(role, memberships, membership_accounts_uuids)
    |> init_descendants_search_or_return(
      account,
      user,
      role,
      memberships,
      membership_accounts_uuids,
      originator
    )
  end

  defp init_search_ancestors(account, role, memberships, membership_accounts_uuids) do
    ancestor_uuids =
      account
      |> Account.get_all_ancestors()
      |> load_uuids(:uuid)

    ancestor_uuids
    |> intersect(membership_accounts_uuids)
    |> search_ancestors(role, memberships, ancestor_uuids)
  end

  defp search_ancestors(uuids_intersect, _role, _memberships, _ancestor_uuids)
       when uuids_intersect == [] do
    nil
  end

  defp search_ancestors([uuid_intersect] = uuids_intersect, role, memberships, _ancestor_uuids)
       when length(uuids_intersect) == 1 do
    membership =
      Enum.find(memberships, fn membership ->
        membership.account_uuid == uuid_intersect
      end)

    role.priority <= membership.role.priority
  end

  defp search_ancestors(uuids_intersect, role, memberships, ancestor_uuids) do
    # ancestor_uuids are sorted by depth, the last one is the lowest one
    # and the one we care about since it's the closest to the current account
    # We filter to only get the relevant accounts while keeping the
    # correct order
    closest_ancestor_uuid =
      ancestor_uuids
      |> Enum.filter(fn ancestor_uuid ->
        Enum.member?(uuids_intersect, ancestor_uuid)
      end)
      |> List.last()

    search_ancestors([closest_ancestor_uuid], role, memberships, ancestor_uuids)
  end

  defp init_descendants_search_or_return(
         nil,
         account,
         user,
         role,
         memberships,
         membership_accounts_uuids,
         originator
       ) do
    descendants_uuids = account |> Account.get_all_descendants() |> load_uuids(:uuid)

    descendants_uuids
    |> intersect(membership_accounts_uuids)
    |> search_descendants(user, role, memberships, originator)
  end

  defp init_descendants_search_or_return(allowed?, _, _, _, _, _, _), do: allowed?

  defp search_descendants([], _, _, _, _), do: true

  defp search_descendants(uuids_intersect, user, role, memberships, originator) do
    Enum.each(uuids_intersect, fn matching_descendant_uuid ->
      membership =
        Enum.find(memberships, fn membership ->
          membership.account_uuid == matching_descendant_uuid
        end)

      if role.priority <= membership.role.priority do
        Membership.unassign(user, membership.account, originator)
      end
    end)

    true
  end

  defp load_uuids(list, field) do
    Enum.map(list, fn element -> Map.get(element, field) end)
  end

  defp intersect(a, b), do: a -- a -- b
end
