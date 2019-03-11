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

defmodule AdminAPI.V1.TransactionController do
  @moduledoc """
  The controller to serve transaction endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.{Changeset, Query}

  alias EWallet.{
    AccountPolicy,
    TransactionPolicy,
    TransactionGate,
    ExportGate,
    AdapterHelper,
    EndUserPolicy
  }

  alias EWallet.Web.{
    Originator,
    Preloader,
    Orchestrator,
    Paginator,
    V1.TransactionOverlay,
    V1.ExportOverlay,
    V1.CSV.TransactionSerializer
  }

  alias EWalletDB.{Account, Transaction, User, Export}

  @doc """
  Creates an export transactions.
  """
  @spec export(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def export(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:export, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized},
         :ok <- AdapterHelper.check_adapter_status(),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns, :originator),
         %Query{} = query <- Orchestrator.build_query(query, TransactionOverlay, attrs),
         {preloads, query} <- extract_preloads(query) do
      query
      |> ExportGate.export("transaction", TransactionSerializer, attrs, preloads: preloads)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  defp extract_preloads(query) do
    preloads = Map.get(query, :preloads, [])
    query = Map.put(query, :preloads, [])
    {preloads, query}
  end

  @doc """
  Retrieves a list of transactions.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:export, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query_records_and_respond(query, attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query
      |> Transaction.query_all_for_account_uuids_and_users([account.uuid])
      |> query_records_and_respond(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query
      |> Transaction.query_all_for_account_uuids_and_users([account.uuid])
      |> query_records_and_respond(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Server endpoint

  Helper action to get the list of all transactions for a specific user,
  identified by a 'provider_user_id'.
  Allows sorting, filtering and pagination.
  This only retrieves the transactions related to the user's primary address. To get
  the transactions for another address, use the `all` action.

  The 'from' and 'to' fields cannot be searched for at the same
  time in the 'search_terms' param.
  """
  @spec all_for_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_user(conn, %{"user_id" => user_id} = attrs) do
    with %User{} = user <- User.get(user_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      user
      |> Transaction.all_for_user(query)
      |> query_records_and_respond(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_user(conn, %{"provider_user_id" => provider_user_id} = attrs) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      user
      |> Transaction.all_for_user(query)
      |> query_records_and_respond(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_user(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Retrieves a specific transaction by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id} = attrs) do
    with %Transaction{} = transaction <- Transaction.get_by(id: id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, transaction) do
      transaction
      |> Orchestrator.one(TransactionOverlay, attrs)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Creates a transaction.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with {:ok, _} <- authorize(:create, conn.assigns, attrs),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, transaction} <- TransactionGate.create(attrs) do
      transaction
      |> Orchestrator.one(TransactionOverlay, attrs)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  defp query_records_and_respond(query, attrs, conn) do
    query
    |> Orchestrator.query(TransactionOverlay, attrs)
    |> respond_multiple(conn)
  end

  # Respond with a list of transactions
  defp respond_multiple(%Paginator{} = paged_transactions, conn) do
    render(conn, :transactions, %{transactions: paged_transactions})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_multiple({:error, code}, conn) do
    handle_error(conn, code)
  end

  # Respond with a single transaction
  defp respond_single(%Transaction{} = transaction, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond_single({:ok, %Transaction{} = transaction}, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond_single({:ok, %Export{} = export}, conn) do
    {:ok, export} = Preloader.preload_one(export, ExportOverlay.default_preload_assocs())
    render(conn, :export, %{export: export})
  end

  defp respond_single({:error, _transaction, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_single({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_single({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:error, code}, conn) do
    handle_error(conn, code)
  end

  defp respond_single(nil, conn) do
    handle_error(conn, :transaction_id_not_found)
  end

  @spec authorize(
          :all | :create | :get | :update | :export,
          map(),
          String.t() | %Account{} | %User{} | map() | nil
        ) :: :ok | {:error, any()} | no_return()
  defp authorize(action, actor, %Account{} = account) do
    AccountPolicy.authorize(action, actor, account)
  end

  defp authorize(action, actor, %User{} = user) do
    EndUserPolicy.authorize(action, actor, user)
  end

  defp authorize(action, actor, data) do
    TransactionPolicy.authorize(action, actor, data)
  end
end
