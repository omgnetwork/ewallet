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

defmodule EWallet.Bouncer.UserTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.Permission
  alias EWalletDB.{Membership, User, Wallet, AccountUser}
  alias EWalletDB.Helpers.Preloader

  def get_owner_uuids(%User{uuid: uuid}) do
    [uuid]
  end

  def get_target_type(%User{is_admin: true}) do
    :admin_users
  end

  def get_target_type(%User{is_admin: false}) do
    :end_users
  end

  def get_query_actor_records(%Permission{type: :accounts, actor: %User{is_admin: true} = actor}) do
    Ecto.assoc(actor, :accounts)
  end

  def get_query_actor_records(%Permission{type: :accounts, actor: %User{is_admin: false} = actor}) do
    Ecto.assoc(actor, :linked_accounts)
  end

  def get_query_actor_records(%Permission{type: :memberships, actor: %User{is_admin: true} = actor}) do
    Ecto.assoc(actor, :memberships)
  end

  def get_query_actor_records(%Permission{type: :memberships, actor: %User{is_admin: false}}) do
    nil
  end

  def get_query_actor_records(%Permission{global_abilities: :accounts, type: :wallets, actor: %User{is_admin: true} = actor}) do
    # wallets owned by users that are linked with accounts that the current user has membership with
    from(
      w in Wallet,
      join: m in Membership,
      on: m.user_uuid == ^actor.uuid,
      join: au in AccountUser,
      on: m.account_uuid == au.account_uuid,
      join: u in User,
      on: au.user_uuid == u.uuid,
      where: w.user_uuid == u.uuid or w.account_uuid == m.account_uuid,
      select: w
    )
  end

  # def get_query_actor_records(%Permission{type: :wallets, actor: %User{is_admin: false} = actor}) do
  #   nil
  # end

  def get_actor_accounts(%User{is_admin: true} = actor) do
    actor = Preloader.preload(actor, [:accounts, :memberships])
    actor.accounts
  end

  def get_actor_accounts(%User{is_admin: false} = actor) do
    actor = Preloader.preload(actor, [:linked_accounts])
    actor.linked_accounts
  end

  def get_target_accounts(%User{is_admin: true} = target) do
    target.accounts
  end

  def get_target_accounts(%User{is_admin: false} = target) do
    target = Preloader.preload(target, [:linked_accounts])
    target.linked_accounts
  end
end
