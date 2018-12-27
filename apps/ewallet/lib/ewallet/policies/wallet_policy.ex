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

defmodule EWallet.WalletPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{AccountPolicy, PolicyHelper, UserPolicy}
  alias EWalletDB.{Account, User, Wallet}

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  def authorize(:all, params, %User{} = user) do
    UserPolicy.authorize(:get, params, user)
  end

  def authorize(:all, _params, nil), do: true

  def authorize(:join, %{admin_user: _} = params, wallet) do
    authorize(:get, params, wallet)
  end

  def authorize(:join, %{key: _} = params, wallet) do
    authorize(:get, params, wallet)
  end

  def authorize(:join, %{end_user: end_user}, %Wallet{} = wallet) do
    end_user
    |> User.addresses()
    |> Enum.member?(wallet.address)
  end

  # Anyone can create a wallet for a user
  def authorize(:create, %{key: _key}, %{"user_id" => user_id}) when not is_nil(user_id) do
    true
  end

  def authorize(:create, %{admin_user: _admin_user}, %{"user_id" => user_id})
      when not is_nil(user_id) do
    true
  end

  # Check with the passed attributes if the current accessor can
  # create a wallet for the account
  def authorize(:create, %{key: key}, %{"account_id" => account_id}) do
    Account.descendant?(key.account, account_id)
  end

  def authorize(:create, %{admin_user: admin_user}, %{"account_id" => account_id}) do
    PolicyHelper.admin_authorize(admin_user, account_id)
  end

  # For wallets owned by users
  def authorize(:create_transaction, %{end_user: end_user}, %Wallet{user_uuid: uuid})
      when not is_nil(uuid) do
    end_user.uuid == uuid
  end

  def authorize(:create_transaction, _params, %Wallet{user_uuid: uuid}) when not is_nil(uuid) do
    with %User{} = _wallet_user <- User.get_by(uuid: uuid) || {:error, :unauthorized} do
      true
    else
      error -> error
    end
  end

  def authorize(:create_transaction, params, %Wallet{account_uuid: uuid}) when not is_nil(uuid) do
    with %Account{} = wallet_account <- Account.get_by(uuid: uuid) || {:error, :unauthorized} do
      AccountPolicy.authorize(:admin, params, wallet_account.id)
    else
      error -> error
    end
  end

  # For wallets owned by users
  def authorize(_action, params, %Wallet{user_uuid: uuid}) when not is_nil(uuid) do
    with %User{} = wallet_user <- User.get_by(uuid: uuid) || {:error, :unauthorized} do
      UserPolicy.authorize(:admin, params, wallet_user)
    else
      error -> error
    end
  end

  # For wallets owned by accounts
  def authorize(_action, params, %Wallet{account_uuid: uuid} = _wallet) when not is_nil(uuid) do
    with %Account{} = wallet_account <- Account.get_by(uuid: uuid) || {:error, :unauthorized} do
      AccountPolicy.authorize(:admin, params, wallet_account.id)
    else
      error -> error
    end
  end

  def authorize(_, _, _), do: false
end
