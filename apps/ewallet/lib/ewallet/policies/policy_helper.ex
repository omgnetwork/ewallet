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

defmodule EWallet.PolicyHelper do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWalletDB.{Account, User, Category, Key, Membership, GlobalRole, Role, Wallet, TransactionConsumption}
  alias Utils.Intersecter
  alias EWalletDB.Helpers.Preloader

  def get_actor(%{admin_user: admin_user}), do: admin_user
  def get_actor(%{end_user: end_user}), do: end_user
  def get_actor(%{key: key}), do: key
  def get_actor(%{originator: %{end_user: end_user}}), do: end_user

  # def can?(attrs, action, type) do
  #   actor = get_actor(attrs)
  #   global_can?(actor, action, type, nil)
  # end

  def can?(actor, attrs) do
    actor = get_actor(actor)
    global_can?(actor, attrs) || account_can?(actor, attrs)
  end

  def global_can?(actor, attrs) do
    actor
    |> Map.get(:global_role, GlobalRole.none())
    |> format_role()
    |> check_global_permissions(actor, GlobalRole.global_role_permissions(), attrs)
  end

  def account_can?(actor, attrs) do
    check_account_permissions(actor, Role.account_role_permissions(), attrs)
  end

  defp check_global_permissions(role, actor, permissions, [action: action, type: type, target: target]) do
    check_global_role(permissions, actor, role, type, action, target)
  end

  defp check_global_permissions(role, _actor, permissions, [action: :all, type: type]) do
    case permissions[role][type][:all] do
      :global ->
        true
      :accounts ->
        true
      :self ->
        true
      _ ->
        false
    end
  end

  defp check_global_permissions(role, actor, permissions, [action: action, target: target]) do
    target_type = get_target_type(target)
    check_global_role(permissions, actor, role, target_type, action, target)
  end

  defp check_global_role(permissions, actor, role, target_type, action, target) do
    case permissions[role][target_type][action] do
      :global ->
        true
      :accounts ->
        # Get all accounts where user have appropriate role
        # Get all accounts to which target belongs
        # Find match
        length(Intersecter.intersect(get_actor_accounts(actor), get_target_accounts(target))) > 0
      :self ->
        IO.inspect("ffipu")
        # TODO
      _ ->
        false
    end
  end

  defp check_account_permissions(actor, permissions, [action: action, type: type, target: target]) do
    check_account_role(permissions, actor, type, action, target)
  end

  defp check_account_permissions(actor, permissions, [action: :all, type: type]) do
    accounts = get_actor_accounts(actor)
    uuids = Enum.map(accounts, fn account -> account.uuid end)
    memberships = Membership.query_all_by_member_and_account_uuids(actor, uuids)

    Enum.any?(memberships, fn membership ->
      role = format_role(membership.role)

      case permissions[role][type][:all] do
        :global   -> true
        :accounts -> true
        :self     -> true
        _         -> false
      end
    end)
  end

  defp check_account_permissions(actor, permissions, [action: action, target: target]) do
    target_type = get_target_type(target)
    check_account_role(permissions, actor, target_type, action, target)
  end

  defp check_account_role(permissions, actor, target_type, action, target) do
    actor_accounts = get_actor_accounts(actor)
    target_accounts = get_target_accounts(target)

    matched_accounts = Intersecter.intersect(actor_accounts, target_accounts)
    uuids = Enum.map(matched_accounts, fn account -> account.uuid end)
    memberships = Membership.query_all_by_member_and_account_uuids(actor, uuids)

    Enum.any?(memberships, fn membership ->
      role = format_role(membership.role)

      case permissions[role][target_type][action] do
        :global ->
          true
        :accounts ->
          true
        _ ->
          false
      end
    end)
  end

  # account transaction consumptions
  defp get_target_type(%TransactionConsumption{user_uuid: nil}) do
    :account_transaction_consumptions
  end

  # account transaction consumptions
  defp get_target_type(%TransactionConsumption{user_uuid: user_uuid}) when not is_nil(user_uuid) do
    :end_user_transaction_consumptions
  end

  defp get_actor_accounts(%User{is_admin: true} = actor) do
    actor.accounts
  end

  defp get_actor_accounts(%User{is_admin: false} = actor) do
    actor = Preloader.preload(actor, [:linked_accounts])
    actor.linked_accounts
  end

  defp get_target_accounts(%Account{} = target) do
    [target]
  end

  defp get_target_accounts(%Category{} = target) do
    target.accounts
  end

  defp get_target_accounts(%User{is_admin: true} = target) do
    target.accounts
  end

  defp get_target_accounts(%User{is_admin: false} = target) do
    target = Preloader.preload(target, [:linked_accounts])
    target.linked_accounts
  end

  defp get_target_accounts(%Key{} = target) do
    target.accounts
  end

  # TO DO
  # defp get_target_accounts(%APIKey{} = target) do

  # Tokens are global
  # defp get_target_accounts(%Token{} = target) do

  # Mints are global
  # defp get_target_accounts(%Mint{} = target) do

  # user wallets
  defp get_target_accounts(%Wallet{account_uuid: nil} = target) do
    get_target_accounts(target.user)
  end

  # account wallets
  defp get_target_accounts(%Wallet{user_uuid: nil} = target) do
    [target.account]
  end

  # account transaction consumptions
  defp get_target_accounts(%TransactionConsumption{user_uuid: nil} = target) do
    [target.account]
  end

  # account transaction consumptions
  defp get_target_accounts(%TransactionConsumption{user_uuid: user_uuid} = target) when not is_nil(user_uuid) do
    get_target_accounts(target.user)
  end

  defp format_role(role) when is_binary(role) do
    String.to_existing_atom(role)
  rescue
    ArgumentError -> nil
  end

  defp format_role(role) when is_atom(role), do: role
end
