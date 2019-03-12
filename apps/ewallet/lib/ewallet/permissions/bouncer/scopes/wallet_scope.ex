# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.Bouncer.WalletScope do
  @moduledoc """
  A module containing the
  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.{Helper, Permission}
  alias EWalletDB.{Wallet, AccountUser, User}

  def scoped_query(%Permission{
        actor: actor,
        global_abilities: global_abilities,
        account_abilities: account_abilities
      }) do
    do_scoped_query(actor, global_abilities) || do_scoped_query(actor, account_abilities)
  end

  # Global + ?
  defp do_scoped_query(_actor, %{account_wallets: :global, end_user_wallets: :global}) do
    Wallet
  end

  defp do_scoped_query(actor, %{account_wallets: :global, end_user_wallets: :accounts}) do
    actor
    |> Helper.query_with_membership_for(Wallet)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid or is_nil(g.user_uuid))
    |> distinct(true)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{account_wallets: :global, end_user_wallets: :self}) do
    where(Wallet, [g], g.user_uuid == ^actor.uuid or is_nil(g.user_uuid))
  end

  defp do_scoped_query(_actor, %{account_wallets: :global, end_user_wallets: _}) do
    where(Wallet, [g], is_nil(g.user_uuid))
  end

  # Accounts + ?
  defp do_scoped_query(actor, %{account_wallets: :accounts, end_user_wallets: :global}) do
    actor
    |> Helper.query_with_membership_for(Wallet)
    |> where([g, m], g.account_uuid == m.account_uuid or is_nil(g.account_uuid))
    |> distinct(true)
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{account_wallets: :accounts, end_user_wallets: :accounts}) do
    actor
    |> Helper.query_with_membership_for(Wallet)
    |> join(:left, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:left, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid or g.account_uuid == m.account_uuid)
    |> distinct(true)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{account_wallets: :accounts, end_user_wallets: :self}) do
    actor
    |> Helper.query_with_membership_for(Wallet)
    |> where([g, m], g.account_uuid == m.account_uuid or g.user_uuid == ^actor.uuid)
    |> distinct(true)
    |> select([g, m], g)
  end

  defp do_scoped_query(actor, %{account_wallets: :accounts, end_user_wallets: _}) do
    actor
    |> Helper.query_with_membership_for(Wallet)
    |> where([g, m], g.account_uuid == m.account_uuid)
    |> select([g, m], g)
  end

  # whatever + ?
  defp do_scoped_query(_actor, %{account_wallets: _, end_user_wallets: :global}) do
    where(Wallet, [g], is_nil(g.account_uuid))
  end

  defp do_scoped_query(actor, %{account_wallets: _, end_user_wallets: :accounts}) do
    actor
    |> Helper.query_with_membership_for(Wallet)
    |> join(:inner, [g, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [g, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([g, m, au, u], g.user_uuid == u.uuid)
    |> select([g, m, au, u], g)
  end

  defp do_scoped_query(actor, %{account_wallets: _, end_user_wallets: :self}) do
    where(Wallet, [g], g.user_uuid == ^actor.uuid)
  end

  defp do_scoped_query(_actor, _a) do
    nil
  end
end
