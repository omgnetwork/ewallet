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

defmodule AdminAPI.V1.BalanceController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.WalletPolicy
  alias EWalletDB.{Wallet, Token}

  alias EWallet.Web.{
    Orchestrator,
    Paginator,
    BalanceLoader,
    V1.TokenOverlay
  }

  @doc """
  Retrieves a list of balances based on current wallet.
  """
  def all_for_wallet(conn, %{"address" => address} = attrs) do
    with %Wallet{} = wallet <- Wallet.get(address) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, wallet),
         %Paginator{data: tokens, pagination: pagination} <- load_tokens(attrs),
         {:ok, data} <- BalanceLoader.add_balances(wallet, tokens) do
      render(conn, :balances, %Paginator{pagination: pagination, data: data})
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def all_for_wallet(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `address` is required.")
  end

  defp load_tokens(attrs) do
    Orchestrator.query(Token, TokenOverlay, attrs)
  end

  defp permit(action, params, data) do
    Bodyguard.permit(WalletPolicy, action, params, data)
  end
end
