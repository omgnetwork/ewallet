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

defmodule EWallet.BalanceFetcher do
  @moduledoc """
  Handles the retrieval and formatting of balances from the local ledger.
  """
  alias EWalletDB.{Token, User, Wallet}

  @spec all(map()) :: {:ok, %EWalletDB.Wallet{}} | {:error, atom()}

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using a user_id.
  """
  def all(%{"user_id" => id}) do
    case User.get(id) do
      nil ->
        {:error, :user_id_not_found}

      user ->
        wallet = User.get_primary_wallet(user)
        {:ok, query_and_add_balances(wallet)}
    end
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using a provider_user_id.
  """
  def all(%{"provider_user_id" => provider_user_id}) do
    case User.get_by_provider_user_id(provider_user_id) do
      nil ->
        {:error, :provider_user_id_not_found}

      user ->
        wallet = User.get_primary_wallet(user)
        {:ok, query_and_add_balances(wallet)}
    end
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using only a list of wallets.
  """
  def all(%{"wallets" => wallets}) do
    {:ok, query_and_add_balances(wallets)}
  end

  @doc """
  Prepare the list of balances for specified tokens and turn them into a suitable format for
  EWalletAPI using only a wallet.
  """
  def all(%{"wallet" => wallet, "tokens" => tokens}) do
    {:ok, query_and_add_balances(wallet, %{"tokens" => tokens})}
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using only a wallet.
  """
  def all(%{"wallet" => wallet}) do
    {:ok, query_and_add_balances(wallet)}
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using only an address.
  """
  def all(%{"address" => address}) do
    case Wallet.get(address) do
      nil ->
        {:error, :wallet_not_found}

      wallet ->
        {:ok, query_and_add_balances(wallet)}
    end
  end

  @doc """
  Prepare the list of balances and turn them into a
  suitable format for EWalletAPI using a token_id and an address
  """
  @spec get(String.t(), %Token{}) :: {:ok, %EWalletDB.Wallet{}} | {:error, atom()}
  def get(id, %Wallet{} = wallet) do
    balances =
      id
      |> LocalLedger.Wallet.get_balance(wallet.address)
      |> process_response(wallet, {:some})

    wallet = Map.put(wallet, :balances, balances)

    {:ok, wallet}
  end

  defp query_and_add_balances(wallet_or_wallets, attrs \\ %{})

  defp query_and_add_balances(wallets, _) when is_list(wallets) do
    wallets
    |> Enum.map(fn wallet -> wallet.address end)
    |> LocalLedger.Wallet.all_balances()
    |> process_response(wallets, {:all})
  end

  defp query_and_add_balances(wallet, %{"tokens" => tokens} = attrs) do
    wallet.address
    |> LocalLedger.Wallet.all_balances(attrs)
    |> process_response(wallet, {:some, tokens})
  end

  defp query_and_add_balances(wallet, _) do
    balances =
      wallet.address
      |> LocalLedger.Wallet.all_balances()
      |> process_response(wallet, {:all})

    Map.put(wallet, :balances, balances)
  end

  defp process_response({:ok, data}, wallets, _type) when is_list(wallets) do
    tokens = Token.all()

    Enum.map(wallets, fn wallet ->
      balances = map_tokens(tokens, data[wallet.address])
      Map.put(wallet, :balances, balances)
    end)
  end

  defp process_response({:ok, data}, wallet, type) do
    type
    |> load_tokens(data[wallet.address])
    |> map_tokens(data[wallet.address])
  end

  defp load_tokens({:all}, _), do: Token.all()

  defp load_tokens({:some, preload_tokens}, _), do: preload_tokens

  defp load_tokens({:some}, amounts) do
    amounts |> Map.keys() |> Token.get_all()
  end

  defp map_tokens(tokens, amounts) do
    Enum.map(tokens, fn token ->
      %{
        token: token,
        amount: amounts[token.id] || 0
      }
    end)
  end
end
