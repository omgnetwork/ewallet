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

defmodule EWallet.ExchangeAccountFetcher do
  @moduledoc """
  Fetch exchange account and/or exchange wallet.
  """
  alias EWallet.WalletFetcher
  alias EWalletDB.{Account, Repo}

  def fetch(%{
        "exchange_account_id" => exchange_account_id,
        "exchange_wallet_address" => exchange_wallet_address
      })
      when not is_nil(exchange_account_id) and not is_nil(exchange_wallet_address) do
    with %Account{} = exchange_account <-
           Account.get(exchange_account_id) || {:error, :exchange_account_id_not_found},
         {:ok, exchange_wallet} <- WalletFetcher.get(exchange_account, exchange_wallet_address) do
      {:ok, exchange_wallet}
    else
      {:error, :account_wallet_not_found} ->
        {:error, :exchange_account_wallet_not_found}

      {:error, :account_wallet_mismatch} ->
        {:error, :exchange_account_wallet_mismatch}

      error ->
        error
    end
  end

  def fetch(%{"exchange_account_id" => exchange_account_id})
      when not is_nil(exchange_account_id) do
    with %Account{} = exchange_account <-
           Account.get(exchange_account_id) || {:error, :exchange_account_id_not_found},
         exchange_wallet <- Account.get_primary_wallet(exchange_account) do
      {:ok, exchange_wallet}
    else
      error ->
        error
    end
  end

  def fetch(%{
        "exchange_wallet_address" => exchange_wallet_address
      })
      when not is_nil(exchange_wallet_address) do
    with {:ok, exchange_wallet} <- WalletFetcher.get(nil, exchange_wallet_address),
         exchange_wallet <- Repo.preload(exchange_wallet, [:account]),
         %Account{} <- exchange_wallet.account || {:error, :exchange_address_not_account} do
      {:ok, exchange_wallet}
    else
      {:error, :wallet_not_found} ->
        {:error, :exchange_account_wallet_not_found}

      error ->
        error
    end
  end

  def fetch(_), do: {:ok, nil}
end
