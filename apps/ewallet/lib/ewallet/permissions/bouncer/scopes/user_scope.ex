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

defmodule EWallet.Bouncer.UserScope do
  @moduledoc """
  A module containing the
  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.{Helper, Permission}
  alias EWalletDB.{AccountUser, User}

  @spec scoped_query(EWallet.Bouncer.Permission.t()) :: EWalletDB.Wallet | nil | Ecto.Query.t()
  def scoped_query(%Permission{
        actor: actor,
        global_abilities: global_abilities,
        account_abilities: account_abilities
      }) do
    do_scoped_query(actor, global_abilities) || do_scoped_query(actor, account_abilities)
  end

  # Global + ?
  defp do_scoped_query(_actor, %{admin_users: :global, end_users: :global}) do
    User
  end

  defp do_scoped_query(actor, %{admin_users: :global, end_users: :accounts}) do
    actor
    |> Helper.prepare_query_with_membership_for(User)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.uuid == u.uuid or g.is_admin == true)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{admin_users: :global, end_users: :self}) do
    where(User, [g], g.uuid == ^actor.uuid or g.is_admin == true)
  end

  defp do_scoped_query(_actor, %{admin_users: :global, end_users: _}) do
    where(User, [g], g.is_admin == true)
  end

  # Accounts + ?
  defp do_scoped_query(actor, %{admin_users: :accounts, end_users: :global}) do
    actor
    |> Helper.prepare_query_with_membership_for(User)
    |> where([g, m], g.uuid == m.user_uuid or g.is_admin == false)
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{admin_users: :accounts, end_users: :accounts}) do
    actor
    |> Helper.prepare_query_with_membership_for(User)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.uuid == u.uuid or g.uuid == m.user_uuid)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{admin_users: :accounts, end_users: :self}) do
    actor
    |> Helper.prepare_query_with_membership_for(User)
    |> where([g, m], g.uuid == m.user_uuid or g.uuid == ^actor.uuid)
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{admin_users: :accounts, end_users: _}) do
    actor
    |> Helper.prepare_query_with_membership_for(User)
    |> where([g, m], g.uuid == m.user_uuid)
    |> select([g, m], g)
  end

  # whatever + ?
  defp do_scoped_query(_actor, %{admin_users: _, end_users: :global}) do
    where(User, [g], g.is_admin == false)
  end

  defp do_scoped_query(actor, %{admin_users: _, end_users: :accounts}) do
    actor
    |> Helper.prepare_query_with_membership_for(User)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> where([g, m, au], g.uuid == au.user_uuid)
    |> select([g, m, au], g)
  end

  defp do_scoped_query(actor, %{admin_users: _, end_users: :self}) do
    where(User, [g], g.uuid == ^actor.uuid)
  end

  defp do_scoped_query(_actor, _a) do
    nil
  end
end
