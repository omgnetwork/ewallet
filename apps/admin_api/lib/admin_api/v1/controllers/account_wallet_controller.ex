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

defmodule AdminAPI.V1.AccountWalletController do
  @moduledoc """
  The controller to serve wallets.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.WalletPolicy
  alias EWallet.Web.{Orchestrator, BalanceLoader, Paginator, V1.WalletOverlay}
  alias EWalletDB.{Account, User, Wallet}

  def all_for_account_and_users(conn, attrs) do
    do_all(attrs, :accounts_and_users, conn)
  end

  def all_for_account(conn, attrs) do
    do_all(attrs, :accounts, conn)
  end

  defp do_all(%{"id" => id} = attrs, type, conn) do
    with %Account{} = account <- Account.get(id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account) do
      account
      |> prepare_account_uuids(attrs["owned"])
      |> load_wallets(type)
      |> Orchestrator.query(WalletOverlay, attrs)
      |> BalanceLoader.add_balances()
      |> respond_multiple(conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  defp prepare_account_uuids(account, true = _owned) do
    [account.uuid]
  end

  defp prepare_account_uuids(account, _owned) do
    Account.get_all_descendants_uuids(account)
  end

  defp load_wallets(account_uuids, :accounts) do
    Wallet.query_all_for_account_uuids(Wallet, account_uuids)
  end

  defp load_wallets(account_uuids, :accounts_and_users) do
    Wallet.query_all_for_account_uuids_and_user(Wallet, account_uuids)
  end

  # Respond with a list of wallets
  defp respond_multiple(%Paginator{} = paged_wallets, conn) do
    render(conn, :wallets, %{wallets: paged_wallets})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @spec permit(:all | :create | :get | :update, map(), %Account{} | %User{} | %Wallet{} | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, data) do
    Bodyguard.permit(WalletPolicy, action, params, data)
  end
end
