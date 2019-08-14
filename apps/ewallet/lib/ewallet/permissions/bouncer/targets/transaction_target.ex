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

defmodule EWallet.Bouncer.TransactionTarget do
  @moduledoc """
  Target functions for transactions.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.Dispatcher
  alias EWalletDB.{Account, AccountUser, User, Wallet, Transaction, Repo}

  @spec get_owner_uuids(Transaction.t()) :: [Ecto.UUID.t()]
  def get_owner_uuids(%Transaction{from_account_uuid: uuid}) when not is_nil(uuid) do
    [uuid]
  end

  def get_owner_uuids(%Transaction{from_user_uuid: uuid}) when not is_nil(uuid) do
    [uuid]
  end

  @spec get_target_types() :: [atom()]
  def get_target_types,
    do: [:blockchain_transactions, :account_transactions, :end_user_transactions]

  # Returnin account_transactions type only for transaction made from and to an account.
  # This might cause issues if permissions change in the future.
  @spec get_target_type(Transaction.t()) ::
          :blockchain_transactions | :account_transactions | :end_user_transactions
  def get_target_type(%Transaction{from_blockchain_address: from}) when is_binary(from) do
    :blockchain_transactions
  end

  def get_target_type(%Transaction{from_account_uuid: from_uuid, to_account_uuid: to_uuid})
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    :account_transactions
  end

  def get_target_type(_), do: :end_user_transactions

  @spec get_target_accounts(Transaction.t(), any()) :: [Account.t()]
  def get_target_accounts(%Transaction{from_blockchain_address: from}, _dispatch_config)
      when is_binary(from) do
    []
  end

  def get_target_accounts(
        %Transaction{from_account_uuid: from_uuid, to_account_uuid: to_uuid},
        _dispatch_config
      )
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account
    |> Account.where_in([from_uuid, to_uuid])
    |> distinct(true)
    |> Repo.all()
  end

  def get_target_accounts(
        %Transaction{from_account_uuid: from_uuid, to_user_uuid: to_uuid},
        _dispatch_config
      )
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account
    |> join(:left, [a], au in AccountUser, on: a.uuid == au.account_uuid)
    |> where([a, au, u], au.user_uuid == ^to_uuid or a.uuid == ^from_uuid)
    |> select([a, au, u], a)
    |> distinct(true)
    |> Repo.all()
  end

  def get_target_accounts(
        %Transaction{from_user_uuid: from_uuid, to_account_uuid: to_uuid},
        _dispatch_config
      )
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account
    |> join(:left, [a], au in AccountUser, on: a.uuid == au.account_uuid)
    |> where([a, au, u], au.user_uuid == ^from_uuid or a.uuid == ^to_uuid)
    |> select([a, au, u], a)
    |> distinct(true)
    |> Repo.all()
  end

  def get_target_accounts(
        %Transaction{from_user_uuid: from_uuid, to_user_uuid: to_uuid},
        _dispatch_config
      )
      when not is_nil(from_uuid) and not is_nil(to_uuid) do
    Account
    |> join(:inner, [a], au in AccountUser, on: a.uuid == au.account_uuid)
    |> where([a, au, u], au.user_uuid == ^from_uuid or au.user_uuid == ^to_uuid)
    |> select([a, au, u], a)
    |> distinct(true)
    |> Repo.all()
  end

  def get_target_accounts(%Transaction{uuid: uuid, from: from}, dispatch_config)
      when is_nil(uuid) and not is_nil(from) do
    from
    |> Wallet.get()
    |> Dispatcher.get_target_accounts(dispatch_config)
  end

  def get_target_accounts(
        %Transaction{uuid: uuid, from_account_uuid: from_account_uuid},
        dispatch_config
      )
      when is_nil(uuid) and not is_nil(from_account_uuid) do
    [uuid: from_account_uuid]
    |> Account.get_by()
    |> Dispatcher.get_target_accounts(dispatch_config)
  end

  def get_target_accounts(
        %Transaction{uuid: uuid, from_user_uuid: from_user_uuid},
        dispatch_config
      )
      when is_nil(uuid) and not is_nil(from_user_uuid) do
    [uuid: from_user_uuid]
    |> User.get_by()
    |> Dispatcher.get_target_accounts(dispatch_config)
  end
end
