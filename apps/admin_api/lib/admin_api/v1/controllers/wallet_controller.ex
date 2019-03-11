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

defmodule AdminAPI.V1.WalletController do
  @moduledoc """
  The controller to serve wallets.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{UUIDFetcher, EndUserPolicy, WalletPolicy}
  alias EWallet.Web.{Orchestrator, Originator, Paginator, BalanceLoader, V1.WalletOverlay}
  alias EWalletDB.{Account, User, Wallet}

  @doc """
  Retrieves a list of all wallets the accessor has access to (all accessible
  accounts + all user wallets)
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      do_all(query, attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  @spec all_for_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_user(conn, %{"id" => id} = attrs) do
    with %User{} = user <- User.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      user
      |> Wallet.all_for(query)
      |> do_all(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  def all_for_user(conn, %{"provider_user_id" => provider_user_id} = attrs) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      user
      |> Wallet.all_for(query)
      |> do_all(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  def all_for_user(conn, _), do: handle_error(conn, :invalid_parameter)

  defp do_all(query, attrs, conn) do
    query
    |> Orchestrator.query(WalletOverlay, attrs)
    |> BalanceLoader.add_balances()
    |> respond_multiple(conn)
  end

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"address" => address} = attrs) do
    with %Wallet{} = wallet <- Wallet.get(address) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, wallet),
         {:ok, wallet} <- BalanceLoader.add_balances(wallet) do
      respond_single(wallet, conn, attrs)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with attrs = UUIDFetcher.replace_external_ids(attrs),
         {:ok, _} <- authorize(:create, conn.assigns, attrs),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns) do
      attrs
      |> Wallet.insert_secondary_or_burn()
      |> BalanceLoader.add_balances()
      |> respond_single(conn, attrs)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  @doc """
  Enable or disable a wallet.
  """
  @spec enable_or_disable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def enable_or_disable(conn, %{"address" => address} = attrs) do
    with %Wallet{} = wallet <- Wallet.get(address) || {:error, :unauthorized},
         {:ok, _} <- authorize(:enable_or_disable, conn.assigns, wallet),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- Wallet.enable_or_disable(wallet, attrs),
         {:ok, updated} <- BalanceLoader.add_balances(updated) do
      respond_single(updated, conn, attrs)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def enable_or_disable(conn, _),
    do:
      handle_error(conn, :invalid_parameter, "Invalid parameter provided. `address` is required.")

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

  # Respond with a single wallet
  defp respond_single({:error, changeset}, conn, _attrs) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:ok, wallet}, conn, attrs) do
    {:ok, wallet} = Orchestrator.one(wallet, WalletOverlay, attrs)
    render(conn, :wallet, %{wallet: wallet})
  end

  defp respond_single(%Wallet{} = wallet, conn, attrs) do
    respond_single({:ok, wallet}, conn, attrs)
  end

  @spec authorize(:all | :create | :get | :update, map(), %Account{} | %User{} | %Wallet{} | nil) ::
          :ok | {:error, any()} | no_return()
  defp authorize(action, actor, %User{} = user) do
    EndUserPolicy.authorize(action, actor, user)
  end

  defp authorize(action, actor, data) do
    WalletPolicy.authorize(action, actor, data)
  end
end
