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

defmodule EWallet.Bouncer.TransactionScope do
  @moduledoc """

  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.{Helper, Permission}
  alias EWalletDB.{Transaction, User, AccountUser}

  @spec scoped_query(EWallet.Bouncer.Permission.t()) :: Ecto.Query.t()
  def scoped_query(%Permission{
        actor: actor,
        global_abilities: global_abilities,
        account_abilities: account_abilities
      }) do
    do_scoped_query(actor, global_abilities) || do_scoped_query(actor, account_abilities)
  end

  defp do_scoped_query(_actor, %{account_transactions: :global, end_user_transactions: :global}) do
    Transaction
  end

  defp do_scoped_query(actor, %{account_transactions: :global, end_user_transactions: :accounts}) do
    actor
    |> Helper.prepare_query_with_membership_for(Transaction)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where(
      [g, m, au, u],
      g.from_user_uuid == u.uuid or
        g.to_user_uuid == u.uuid or
        is_nil(g.from_user_uuid) or
        is_nil(g.to_user_uuid)
    )
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{account_transactions: :global, end_user_transactions: :self}) do
    where(
      Transaction,
      [g],
      g.from_user_uuid == ^actor.uuid or
        g.to_user_uuid == ^actor.uuid or
        is_nil(g.from_user_uuid) or
        is_nil(g.to_user_uuid)
    )
  end

  defp do_scoped_query(_actor, %{account_transactions: :global, end_user_transactions: _}) do
    where(Transaction, [g], is_nil(g.from_user_uuid) or is_nil(g.to_user_uuid))
  end

  # Accounts + ?
  defp do_scoped_query(actor, %{account_transactions: :accounts, end_user_transactions: :global}) do
    actor
    |> Helper.prepare_query_with_membership_for(Transaction)
    |> where(
      [g, m],
      g.from_account_uuid == m.account_uuid or
        g.to_account_uuid == m.account_uuid or
        is_nil(g.from_account_uuid) or
        is_nil(g.to_account_uuid)
    )
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{account_transactions: :accounts, end_user_transactions: :accounts}) do
    actor
    |> Helper.prepare_query_with_membership_for(Transaciton)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where(
      [g, m, au, u],
      g.from_user_uuid == u.uuid or
        g.to_user_uuid == u.uuid or
        g.from_account_uuid == m.account_uuid or
        g.to_account_uuid == m.account_uuid
    )
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{account_transactions: :accounts, end_user_transactions: :self}) do
    actor
    |> Helper.prepare_query_with_membership_for(Transaction)
    |> where(
      [g, m],
      g.from_account_uuid == m.account_uuid or
        g.to_account_uuid == m.account_uuid or
        g.from_user_uuid == ^actor.uuid or
        g.to_user_uuid == ^actor.uuid
    )
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{account_transactions: :accounts, end_user_transactions: _}) do
    actor
    |> Helper.prepare_query_with_membership_for(Transaction)
    |> where([g, m], g.from_account_uuid == m.account_uuid or g.to_account_uuid == m.account_uuid)
    |> select([g, m], g)
  end

  defp do_scoped_query(_actor, %{account_transactions: _, end_user_transactions: :global}) do
    where(Transaction, [g], is_nil(g.from_account_uuid) and is_nil(g.to_account_uuid))
  end

  defp do_scoped_query(actor, %{account_transactions: _, end_user_transactions: :accounts}) do
    actor
    |> Helper.prepare_query_with_membership_for(Transaction)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.from_user_uuid == u.uuid or g.to_user_uuid == u.uuid)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{account_transactions: _, end_user_transactions: :self}) do
    where(Transaction, [g], g.from_user_uuid == ^actor.uuid or g.to_user_uuid == ^actor.uuid)
  end

  defp do_scoped_query(_actor, _a) do
    nil
  end
end
