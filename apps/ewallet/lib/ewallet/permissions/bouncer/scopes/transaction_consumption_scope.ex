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

defmodule EWallet.Bouncer.TransactionConsumptionScope do
  @moduledoc """

  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.{Helper, Permission}
  alias EWalletDB.TransactionConsumption

  @spec scoped_query(EWallet.Bouncer.Permission.t()) :: any()
  def scoped_query(%Permission{
        actor: actor,
        global_abilities: global_abilities,
        account_abilities: account_abilities
      }) do
    do_scoped_query(actor, global_abilities) || do_scoped_query(actor, account_abilities)
  end

  # Global + ?
  defp do_scoped_query(_actor, %{
         account_transaction_consumptions: :global,
         end_user_transaction_consumptions: :global
       }) do
    TransactionConsumption
  end

  defp do_scoped_query(actor, %{
         account_transaction_consumptions: :global,
         end_user_transaction_consumptions: :accounts
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionConsumption)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid or is_nil(g.user_uuid))
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_consumptions: :global,
         end_user_transaction_consumptions: :self
       }) do
    where(TransactionConsumption, [g], g.user_uuid == ^actor.uuid or is_nil(g.user_uuid))
  end

  defp do_scoped_query(_actor, %{
         account_transaction_consumptions: :global,
         end_user_transaction_consumptions: _
       }) do
    where(TransactionConsumption, [g], is_nil(g.user_uuid))
  end

  # Accounts + ?
  defp do_scoped_query(actor, %{
         account_transaction_consumptions: :accounts,
         end_user_transaction_consumptions: :global
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionConsumption)
    |> where([g, m], g.account_uuid == m.account_uuid or is_nil(g.account_uuid))
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_consumptions: :accounts,
         end_user_transaction_consumptions: :accounts
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionConsumption)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid or g.account_uuid == m.account_uuid)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_consumptions: :accounts,
         end_user_transaction_consumptions: :self
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionConsumption)
    |> where([g, m], g.account_uuid == m.account_uuid or g.user_uuid == ^actor.uuid)
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_consumptions: :accounts,
         end_user_transaction_consumptions: _
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionConsumption)
    |> where([g, m], g.account_uuid == m.account_uuid)
    |> select([g, m], g)
  end

  # whatever + ?
  defp do_scoped_query(_actor, %{
         account_transaction_consumptions: _,
         end_user_transaction_consumptions: :global
       }) do
    where(Wallet, [g], is_nil(g.account_uuid))
  end

  defp do_scoped_query(actor, %{
         account_transaction_consumptions: _,
         end_user_transaction_consumptions: :accounts
       }) do
    actor
    |> Helper.prepare_query_with_membership_for(TransactionConsumption)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{
         account_transaction_consumptions: _,
         end_user_transaction_consumptions: :self
       }) do
    where(TransactionConsumption, [g], g.user_uuid == ^actor.uuid)
  end

  defp do_scoped_query(_actor, _a) do
    nil
  end
end
