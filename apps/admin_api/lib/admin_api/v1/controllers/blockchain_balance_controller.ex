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

defmodule AdminAPI.V1.BlockchainBalanceController do
  @moduledoc """
  The controller to serve paginated balances for specified blockchain wallet.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.BlockchainWalletPolicy
  alias EWalletDB.{BlockchainWallet, Token}
  alias AdminAPI.V1.BalanceView

  alias EWallet.Web.{
    Orchestrator,
    Paginator,
    BlockchainBalanceLoader,
    V1.TokenOverlay
  }

  @doc """
  Retrieves a paginated list of balances by given blockchain wallet address.
  """
  def all_for_wallet(conn, %{"address" => address} = attrs) do
    with %BlockchainWallet{} = wallet <-
           BlockchainWallet.get_by(address: address) || {:error, :unauthorized},
         {:ok, _} <- authorize(:view_balance, conn.assigns, wallet),
         %Paginator{data: tokens, pagination: pagination} <- paginated_tokens(attrs),
         {:ok, data} <- BlockchainBalanceLoader.balances_for_address(address, tokens) do
      render(conn, BalanceView, :balances, %Paginator{pagination: pagination, data: data})
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def all_for_wallet(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `address` is required.")
  end

  defp paginated_tokens(%{"token_addresses" => addresses} = attrs) do
    addresses
    |> Token.query_all_by_blockchain_addresses()
    |> paginated_blockchain_tokens(attrs)
  end

  defp paginated_tokens(%{"token_ids" => ids} = attrs) do
    ids
    |> Token.query_all_by_ids()
    |> paginated_blockchain_tokens(attrs)
  end

  defp paginated_tokens(attrs), do: paginated_blockchain_tokens(Token, attrs)

  defp paginated_blockchain_tokens(query, attrs) do
    query
    |> Token.query_all_blockchain()
    |> Orchestrator.query(TokenOverlay, attrs)
  end

  defp authorize(action, actor, data) do
    BlockchainWalletPolicy.authorize(action, actor, data)
  end
end
