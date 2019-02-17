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

defmodule EWallet.WalletFetcher do
  @moduledoc """
  Handles the retrieval of wallets from the eWallet database.
  """
  alias EWalletDB.{Account, User, Wallet}

  @spec get(%User{} | %Account{} | nil, String.t() | nil) :: {:ok, %Wallet{}} | {:error, atom()}
  def get(%User{} = user, nil) do
    {:ok, User.get_primary_wallet(user)}
  end

  def get(%Account{} = account, nil) do
    {:ok, Account.get_primary_wallet(account)}
  end

  def get(nil, address) do
    with %Wallet{} = wallet <- Wallet.get(address) || :wallet_not_found do
      {:ok, wallet}
    else
      error -> {:error, error}
    end
  end

  def get(%User{} = user, address) do
    with %Wallet{} = wallet <- Wallet.get(address) || :user_wallet_not_found,
         true <- wallet.user_uuid == user.uuid || :user_wallet_mismatch do
      {:ok, wallet}
    else
      error -> {:error, error}
    end
  end

  def get(%Account{} = account, address) do
    with %Wallet{} = wallet <- Wallet.get(address) || :account_wallet_not_found,
         true <- wallet.account_uuid == account.uuid || :account_wallet_mismatch do
      {:ok, wallet}
    else
      error -> {:error, error}
    end
  end

  def get(_, _), do: {:error, :invalid_parameter}
end
