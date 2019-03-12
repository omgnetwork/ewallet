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

defmodule AdminAPI.V1.AccountWalletController do
  @moduledoc """
  The controller to serve account wallets.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{AccountPolicy, WalletPolicy}
  alias EWallet.Web.{Orchestrator, BalanceLoader, Paginator, V1.WalletOverlay}
  alias EWalletDB.{Account, Wallet}

  def all_for_account_and_users(conn, attrs) do
    do_all(attrs, :accounts_and_users, conn)
  end

  def all_for_account(conn, attrs) do
    do_all(attrs, :accounts, conn)
  end

  defp do_all(%{"id" => id} = attrs, type, conn) do
    with %Account{} = account <- Account.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query
      |> load_wallets(account, type)
      |> Orchestrator.query(WalletOverlay, attrs)
      |> BalanceLoader.add_balances()
      |> respond_multiple(conn)
    else
      {:error, error} ->
        handle_error(conn, error)

      error ->
        handle_error(conn, error)
    end
  end

  defp do_all(_, _, conn), do: handle_error(conn, :missing_id)

  defp load_wallets(query, account, :accounts) do
    Wallet.query_all_for_account_uuids(query, [account.uuid])
  end

  defp load_wallets(query, account, :accounts_and_users) do
    Wallet.query_all_for_account_uuids_and_user(query, [account.uuid])
  end

  # Respond with a list of wallets
  defp respond_multiple(%Paginator{} = paged_wallets, conn) do
    render(conn, :wallets, %{wallets: paged_wallets})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_multiple({:error, code}, conn) do
    handle_error(conn, code)
  end

  @spec authorize(:all, map(), any()) :: :ok | {:error, any()} | no_return()
  defp authorize(action, actor, %Account{} = account) do
    AccountPolicy.authorize(action, actor, account)
  end

  defp authorize(action, actor, wallet) do
    WalletPolicy.authorize(action, actor, wallet)
  end
end
