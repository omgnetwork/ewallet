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

defmodule EWallet.Bouncer.TransactionRequestScope do
  @moduledoc """

  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.{Helper, Permission}
  alias EWalletDB.{TransactionRequest, AccountUser, User}

  @spec scoped_query(EWallet.Bouncer.Permission.t()) :: Ecto.Queryable.t()
  def scoped_query(%Permission{
        actor: actor,
        global_abilities: global_abilities,
        account_abilities: account_abilities
      }) do
    do_scoped_query(actor, global_abilities) || do_scoped_query(actor, account_abilities)
  end

  # Global + ?
  defp do_scoped_query(_actor, %{
         account_transaction_requests: :global,
         end_user_transaction_requests: :global
       }) do
    TransactionRequest
  end

  defp do_scoped_query(actor, %{
         account_transaction_requests: :global,
         end_user_transaction_requests: :accounts
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionRequest)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid or not is_nil(g.account_uuid))
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_requests: :global,
         end_user_transaction_requests: :self
       }) do
    where(TransactionRequest, [g], g.user_uuid == ^actor.uuid or not is_nil(g.account_uuid))
  end

  defp do_scoped_query(_actor, %{
         account_transaction_requests: :global,
         end_user_transaction_requests: _
       }) do
    where(TransactionRequest, [g], not is_nil(g.account_uuid))
  end

  # Accounts + ?
  defp do_scoped_query(actor, %{
         account_transaction_requests: :accounts,
         end_user_transaction_requests: :global
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionRequest)
    |> where([g, m], g.account_uuid == m.account_uuid or not is_nil(g.user_uuid))
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_requests: :accounts,
         end_user_transaction_requests: :accounts
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionRequest)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid or g.account_uuid == m.account_uuid)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_requests: :accounts,
         end_user_transaction_requests: :self
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionRequest)
    |> where([g, m], g.account_uuid == m.account_uuid or g.user_uuid == ^actor.uuid)
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_requests: :accounts,
         end_user_transaction_requests: _
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionRequest)
    |> where([g, m], g.account_uuid == m.account_uuid)
    |> select([g, m], g)
  end

  # whatever + ?
  defp do_scoped_query(_actor, %{
         account_transaction_requests: _,
         end_user_transaction_requests: :global
       }) do
    where(Wallet, [g], not is_nil(g.user_uuid))
  end

  defp do_scoped_query(actor, %{
         account_transaction_requests: _,
         end_user_transaction_requests: :accounts
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionRequest)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_requests: _,
         end_user_transaction_requests: :self
       }) do
    where(TransactionRequest, [g], g.user_uuid == ^actor.uuid)
  end

  defp do_scoped_query(_actor, _a) do
    nil
  end
end
