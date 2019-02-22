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

defmodule EWallet.Bouncer.TransactionTarget do
  @moduledoc """
  Target functions for transactions.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.{UserTarget, AccountTarget, WalletTarget}
  alias EWalletDB.{Account, AccountUser, User, Wallet, Transaction}

  @spec get_owner_uuids(EWalletDB.Transaction.t()) :: [...]
  def get_owner_uuids(%Transaction{from_account_uuid: uuid}) when not is_nil(uuid) do
    [uuid]
  end

  def get_owner_uuids(%Transaction{from_user_uuid: uuid}) when not is_nil(uuid) do
    [uuid]
  end

  def get_target_types(), do: [:account_transactions, :end_user_transactions]
  def get_target_type(%Transaction{}), do: :transactions

  def get_target_accounts(%Transaction{from_account_uuid: from_uuid, to_account_uuid: to_uuid})
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account.where_in(Account, [from_uuid, to_uuid])
  end

  def get_target_accounts(%Transaction{from_account_uuid: from_uuid, to_user_uuid: to_uuid})
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account
    |> join(:inner, [a], au in AccountUser, on: a.account_uuid == au.account_uuid)
    |> where([a, au, u], au.user_uuid == ^to_uuid or a.account_uuid == ^from_uuid)
    |> select([a, au, u], a)
  end

  def get_target_accounts(%Transaction{from_user_uuid: from_uuid, to_account_uuid: to_uuid})
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account
    |> join(:inner, [a], au in AccountUser, on: a.account_uuid == au.account_uuid)
    |> where([a, au, u], au.user_uuid == ^from_uuid or a.account_uuid == ^to_uuid)
    |> select([a, au, u], a)
  end

  def get_target_accounts(%Transaction{from_user_uuid: from_uuid, to_user_uuid: to_uuid})
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account
    |> join(:inner, [a], au in AccountUser, on: a.account_uuid == au.account_uuid)
    |> where([a, au, u], au.user_uuid == ^from_uuid or au.user_uuid == ^to_uuid)
    |> select([a, au, u], a)
  end

  def get_target_accounts(%Transaction{uuid: uuid, from: from})
      when is_nil(uuid) and not is_nil(from) do
    from
    |> Wallet.get()
    |> WalletTarget.get_target_accounts()
  end

  def get_target_accounts(%Transaction{uuid: uuid, from_account_uuid: from_account_uuid})
      when is_nil(uuid) and not is_nil(from_account_uuid) do
    [uuid: from_account_uuid]
    |> Account.get_by()
    |> AccountTarget.get_target_accounts()
  end

  def get_target_accounts(%Transaction{uuid: uuid, from_user_uuid: from_user_uuid})
      when is_nil(uuid) and not is_nil(from_user_uuid) do
    [uuid: from_user_uuid]
    |> User.get_by()
    |> UserTarget.get_target_accounts()
  end
end
