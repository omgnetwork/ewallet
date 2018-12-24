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

defmodule EWallet.TransactionConsumptionPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{AccountPolicy, PolicyHelper, TransactionRequestPolicy, UserPolicy, WalletPolicy}
  alias EWalletDB.{Account, TransactionConsumption, TransactionRequest, User, Wallet}

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  def authorize(:all, params, %User{} = user) do
    UserPolicy.authorize(:get, params, user)
  end

  def authorize(:all, params, %TransactionRequest{} = transaction_request) do
    TransactionRequestPolicy.authorize(:get, params, transaction_request)
  end

  def authorize(:all, params, %Wallet{} = wallet) do
    WalletPolicy.authorize(:get, params, wallet)
  end

  def authorize(:all, _admin_user_or_key, nil), do: true

  # If the account_uuid is nil, the transaction belongs to a user and can be
  # seen by any admin.
  def authorize(:get, _key_or_user, %TransactionConsumption{account_uuid: nil}) do
    true
  end

  def authorize(:get, %{key: key}, consumption) do
    Account.descendant?(key.account, consumption.account.id)
  end

  def authorize(:get, %{admin_user: user}, consumption) do
    PolicyHelper.viewer_authorize(user, consumption.account.id)
  end

  def authorize(:join, %{admin_user: _} = params, consumption) do
    authorize(:get, params, consumption)
  end

  def authorize(:join, %{key: _} = params, consumption) do
    authorize(:get, params, consumption)
  end

  def authorize(:join, %{end_user: _} = params, consumption) do
    WalletPolicy.authorize(:join, params, consumption.wallet)
  end

  def authorize(:consume, params, %TransactionConsumption{} = consumption) do
    WalletPolicy.authorize(:admin, params, consumption.wallet)
  end

  # To confirm a request, we need to have admin rights on the
  # wallet of the request, except for user-only request/consumption
  def authorize(:confirm, %{end_user: end_user}, %TransactionRequest{} = request) do
    end_user.uuid == request.wallet.user_uuid
  end

  def authorize(:confirm, params, %TransactionRequest{} = request) do
    WalletPolicy.authorize(:admin, params, request.wallet)
  end

  def authorize(_, _, _), do: false
end
