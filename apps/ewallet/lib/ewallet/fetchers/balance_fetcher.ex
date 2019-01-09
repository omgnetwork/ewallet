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

defmodule EWallet.BalanceFetcher do
  @moduledoc """
  Handles the retrieval and formatting of balances from the local ledger.
  """
  alias EWalletDB.{Token, User, Wallet}

  @spec all(map()) :: {:ok, %EWalletDB.Wallet{}} | {:error, atom()}

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using a user_id.

  ## Examples

    res = BalanceFetcher.all(%{"user_id" => "usr_12345678901234567890123456"})

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"user_id" => id}) do
    case User.get(id) do
      nil ->
        {:error, :user_id_not_found}

      user ->
        wallet = User.get_primary_wallet(user)
        {:ok, format_all(wallet)}
    end
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using a provider_user_id.

  ## Examples

    res = BalanceFetcher.all(%{"provider_user_id" => "123"})

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"provider_user_id" => provider_user_id}) do
    case User.get_by_provider_user_id(provider_user_id) do
      nil ->
        {:error, :provider_user_id_not_found}

      user ->
        wallet = User.get_primary_wallet(user)
        {:ok, format_all(wallet)}
    end
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using only a wallet.

  ## Examples

    res = BalanceFetcher.all(%Wallet{})

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"wallet" => wallet}) do
    {:ok, format_all(wallet)}
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using only a list of wallets.

  ## Examples

    res = BalanceFetcher.all([%Wallet{}])

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"wallets" => wallets}) do
    {:ok, format_all(wallets)}
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using only an address.

  ## Examples

    res = BalanceFetcher.all(%{"address" => "d26fc18f-d403-4a39-a039-21e2bc713688"})

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"address" => address}) do
    case Wallet.get(address) do
      nil ->
        {:error, :wallet_not_found}

      wallet ->
        {:ok, format_all(wallet)}
    end
  end

  @doc """
  Prepare the list of balances and turn them into a
  suitable format for EWalletAPI using a user and a token_id

  ## Examples

    res = Wallet.get_balance(user, "tok_OMG_01cbennsd8q4xddqfmewpwzxdy")

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def get(%User{} = user, %Token{} = token) do
    user_wallet = User.get_primary_wallet(user)
    get(token.id, user_wallet)
  end

  @doc """
  Prepare the list of balances and turn them into a
  suitable format for EWalletAPI using a token_id and an address

  ## Examples

    res = Wallet.get_balance("tok_OMG_01cbennsd8q4xddqfmewpwzxdy", "22a83591-d684-4bfd-9310-6bdecdec4f81")

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def get(id, %Wallet{} = wallet) do
    wallet =
      id
      |> LocalLedger.Wallet.get_balance(wallet.address)
      |> process_response(wallet, :one)

    {:ok, wallet}
  end

  defp format_all(wallets) when is_list(wallets) do
    wallets
    |> Enum.map(fn wallet -> wallet.address end)
    |> LocalLedger.Wallet.all_balances()
    |> process_response(wallets, :all)
  end

  defp format_all(wallet) do
    wallet.address
    |> LocalLedger.Wallet.all_balances()
    |> process_response(wallet, :all)
  end

  defp process_response({:ok, data}, wallets, type) when is_list(wallets) do
    Enum.map(wallets, fn wallet ->
      balances =
        type
        |> load_tokens(data[wallet.address])
        |> map_tokens(data[wallet.address])

      Map.put(wallet, :balances, balances)
    end)
  end

  defp process_response({:ok, data}, wallet, type) do
    balances =
      type
      |> load_tokens(data[wallet.address])
      |> map_tokens(data[wallet.address])

    Map.put(wallet, :balances, balances)
  end

  defp load_tokens(:all, _), do: Token.all()

  defp load_tokens(:one, amounts) do
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
