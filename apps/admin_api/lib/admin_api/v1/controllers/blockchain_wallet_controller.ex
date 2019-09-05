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

defmodule AdminAPI.V1.BlockchainWalletController do
  @moduledoc """
  The controller to serve paginated balances for specified blockchain wallet.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{BlockchainHelper, BlockchainWalletPolicy, ChildchainTransactionGate}
  alias EWalletDB.{BlockchainWallet, Token, Transaction}
  alias AdminAPI.V1.{BalanceView, TransactionView}

  alias EWallet.Web.{
    Orchestrator,
    Paginator,
    Originator,
    BlockchainBalanceLoader,
    V1.BlockchainWalletOverlay,
    V1.TokenOverlay
  }

  @doc """
  Creates a new blockchain wallet with the provided params.
  Currently, only `cold` type is supported.
  Required attributes are `type`, `address` and `name`.
  Returns the serialized created cold blockchain wallet.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"type" => "cold", "address" => _, "name" => _} = attrs) do
    with {:ok, _} <- authorize(:create, conn.assigns, attrs),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         identifier <- BlockchainHelper.rootchain_identifier(),
         attrs <- Map.put(attrs, "blockchain_identifier", identifier),
         {:ok, wallet} <- BlockchainWallet.insert_cold(attrs) do
      respond_single(wallet, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def create(conn, %{"type" => _}) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter error. The specified `type` is not currently supported."
    )
  end

  def create(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter provided. `type`, `address` and `name` are required."
    )
  end

  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  @doc """
  Retrives paginated multiple wallets
  """
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query
      |> Orchestrator.query(BlockchainWalletOverlay, attrs)
      |> respond_multiple(conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  @doc """
  Retrieves a wallet with the given blockchain wallet address.
  """
  def get(conn, %{"address" => address} = attrs) when not is_nil(address) do
    with %BlockchainWallet{} = wallet <-
           BlockchainWallet.get_by(address: address) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, wallet),
         {:ok, wallet} <- Orchestrator.one(wallet, BlockchainWalletOverlay, attrs) do
      respond_single(wallet, conn)
    else
      {:error, error} -> handle_error(conn, error)
      {:error, error, description} -> handle_error(conn, error, description)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Retrieves a paginated list of balances by given blockchain wallet address.
  """
  def all_for_wallet(conn, %{"address" => address} = attrs) do
    with %BlockchainWallet{} = wallet <-
           BlockchainWallet.get_by(address: address) || {:error, :unauthorized},
         {:ok, _} <- authorize(:view_balance, conn.assigns, wallet),
         %Paginator{data: tokens, pagination: pagination} <- paginated_tokens(attrs),
         identifier <- attrs["blockchain_identifier"] || BlockchainHelper.rootchain_identifier(),
         :ok <- BlockchainHelper.validate_identifier(identifier),
         {:ok, data} <- BlockchainBalanceLoader.balances(wallet.address, tokens, identifier) do
      render(conn, BalanceView, :balances, %Paginator{pagination: pagination, data: data})
    else
      {:error, error} -> handle_error(conn, error)
      {:error, error, description} -> handle_error(conn, error, description)
    end
  end

  def all_for_wallet(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `address` is required.")
  end

  def deposit_to_childchain(conn, %{"address" => address} = attrs) when not is_nil(address) do
    with %BlockchainWallet{} = wallet <-
           BlockchainWallet.get_by(address: address) || {:error, :unauthorized},
         {:ok, _} <- authorize(:deposit_to_childchain, conn.assigns, wallet),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, transaction} <- ChildchainTransactionGate.deposit(conn.assigns, attrs) do
      respond_single(transaction, conn)
    else
      {:error, error} -> handle_error(conn, error)
      {:error, error, description} -> handle_error(conn, error, description)
    end
  end

  def deposit_to_childchain(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter provided. `address` is required."
    )
  end

  defp respond_single(%BlockchainWallet{} = blockchain_wallet, conn) do
    render(conn, :blockchain_wallet, %{blockchain_wallet: blockchain_wallet})
  end

  defp respond_single(%Transaction{} = transaction, conn) do
    render(conn, TransactionView, :transaction, %{transaction: transaction})
  end

  defp respond_multiple(%Paginator{} = paged_wallets, conn) do
    render(conn, :blockchain_wallets, %{blockchain_wallets: paged_wallets})
  end

  defp paginated_tokens(%{"token_addresses" => addresses} = attrs) do
    identifier = BlockchainHelper.rootchain_identifier()

    addresses
    |> Token.query_all_by_blockchain_addresses(identifier)
    |> paginated_blockchain_tokens(attrs)
  end

  defp paginated_tokens(%{"token_ids" => ids} = attrs) do
    ids
    |> Token.query_all_by_ids()
    |> paginated_blockchain_tokens(attrs)
  end

  defp paginated_tokens(attrs), do: paginated_blockchain_tokens(Token, attrs)

  defp paginated_blockchain_tokens(query, attrs) do
    BlockchainHelper.rootchain_identifier()
    |> Token.query_all_blockchain(query)
    |> Orchestrator.query(TokenOverlay, attrs)
  end

  defp authorize(action, actor, data) do
    BlockchainWalletPolicy.authorize(action, actor, data)
  end
end
