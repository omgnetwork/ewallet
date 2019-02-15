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

defmodule EWallet.Bouncer.WalletScope do
  @moduledoc """
  A module containing the
  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.{Permission, Dispatcher}

  # defmacro macro_unless(clause, do: expression) do
  #   quote do
  #     if(!unquote(clause), do: unquote(expression))
  #   end
  # end

  # Global permissions

  # Global + ?
  def scoped_query(%Permission{global_abilities: %{account_wallets: :global, user_wallets: :global}}) do
    Wallet
  end

  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: :global, user_wallets: :accounts}}) do
    actor
    |> Wallet.prepare_query_with_membership_for()
    |> join(:inner, [w, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [w, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([w, m, au, u], w.user_uuid == u.uuid or is_nil(w.user_uuid))
    |> select([w, m, au, u], w)
  end

  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: :global, user_wallets: :self}}) do
    where(Wallet, [w], w.user_uuid == ^actor.uuid or is_nil(w.user_uuid))
  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :global, user_wallets: _}}) do
    where(Wallet, [w], is_nil(w.user_uuid))
  end

  # Accounts + ?
  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: :accounts, user_wallets: :global}}) do
    actor
    |> Wallet.prepare_query_with_membership_for()
    |> where([w, m], w.account_uuid == m.account_uuid or is_nil(w.account_uuid))
    |> select([w, m], w)
  end

  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: :accounts, user_wallets: :accounts}}) do
    actor
    |> Wallet.prepare_query_with_membership_for()
    |> join(:inner, [w, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [w, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([w, m, au, u], w.user_uuid == u.uuid or w.account_uuid == m.account_uuid)
    |> select([w, m, au, u], w)
  end

  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: :accounts, user_wallets: :self}}) do
    actor
    |> Wallet.prepare_query_with_membership_for()
    |> where([w, m], w.account_uuid == m.account_uuid or w.user_uuid == ^actor.uuid)
    |> select([w, m], w)
  end

  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: :accounts, user_wallets: _}}) do
    actor
    |> Wallet.prepare_query_with_membership_for()
    |> where([w, m], w.account_uuid == m.account_uuid)
    |> select([w, m], w)
  end

  # whatever + ?
  def scoped_query(%Permission{global_abilities: %{account_wallets: _, user_wallets: :global}}) do
    where(Wallet, [w], is_nil(w.account_uuid))
  end

  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: _, user_wallets: :accounts}}) do
    actor
    |> Wallet.prepare_query_with_membership_for()
    |> join(:inner, [w, m], au in AccountUser, on: m.account_uuid == au.account_uuid)
    |> join(:inner, [w, m, au], u in User, on: au.user_uuid == u.uuid)
    |> where([w, m, au, u], w.user_uuid == u.uuid)
    |> select([w, m, au, u], w)
  end

  def scoped_query(%Permission{actor: actor, global_abilities: %{account_wallets: _, user_wallets: :self}}) do
    where(Wallet, [w], w.user_uuid == ^actor.uuid)
  end

  def scoped_query(_) do
    Ecto.Query
  end
end
