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

defmodule EWallet.TransactionPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{AccountPolicy, PolicyHelper, WalletPolicy}
  alias EWalletDB.{Account, Wallet}

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  # Everyone can see all the transactions
  def authorize(:all, _admin_user_or_key, _data), do: true
  def authorize(:export, _admin_user_or_key, _data), do: true

  # Anyone can get a transaction
  def authorize(:get, _admin_user_or_key, _data) do
    true
  end

  # Check with the passed attributes if the current accessor can
  # create a transaction for the account
  def authorize(:create, params, %{"from_address" => from_address})
      when not is_nil(from_address) do
    with %Wallet{} = wallet <- Wallet.get(from_address) do
      WalletPolicy.authorize(:create_transaction, params, wallet)
    else
      _error -> {:error, :unauthorized}
    end
  end

  # Anyone can create a request for a user
  def authorize(:create, _params, %{"from_provider_user_id" => from_provider_user_id})
      when not is_nil(from_provider_user_id) do
    true
  end

  def authorize(:create, _params, %{"from_user_id" => from_user_id})
      when not is_nil(from_user_id) do
    true
  end

  def authorize(:create, %{key: key}, %{"account_uuid" => account_uuid})
      when not is_nil(account_uuid) do
    Account.descendant?(key.account, account_uuid)
  end

  def authorize(:create, %{key: key}, %{"from_account_id" => account_id})
      when not is_nil(account_id) do
    Account.descendant?(key.account, account_id)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"account_uuid" => account_uuid})
      when not is_nil(account_uuid) do
    PolicyHelper.admin_authorize(admin_user, account_uuid)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"from_account_id" => account_id})
      when not is_nil(account_id) do
    PolicyHelper.admin_authorize(admin_user, account_id)
  end

  def authorize(_, _, _), do: false
end
