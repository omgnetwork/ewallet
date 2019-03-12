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

defmodule AdminAPI.V1.TransactionRequestController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{TransactionRequestPolicy, AccountPolicy}
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.TransactionRequestOverlay}
  alias Ecto.Changeset

  alias EWallet.{
    TransactionRequestFetcher,
    TransactionRequestGate
  }

  alias Utils.Helpers.UUID

  alias EWalletDB.{Account, TransactionRequest}

  @spec all(Plug.Conn.t(), map) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      do_all(query, attrs, conn)
    else
      error -> respond(error, conn)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized},
         user_uuids <- [account.uuid] |> Account.get_all_users() |> UUID.get_uuids() do
      [account.uuid]
      |> TransactionRequest.query_all_for_account_and_user_uuids(user_uuids, query)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn)
    end
  end

  def all_for_account(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `id` is required.")
  end

  @spec do_all(Ecto.Queryable.t(), map(), Plug.Conn.t()) :: Plug.Conn.t()
  defp do_all(query, attrs, conn) do
    query
    |> Orchestrator.query(TransactionRequestOverlay, attrs)
    |> respond_multiple(conn)
  end

  @spec get(Plug.Conn.t(), map) :: Plug.Conn.t()
  def get(conn, %{"formatted_id" => formatted_id}) do
    with {:ok, request} <- TransactionRequestFetcher.get(formatted_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, request) do
      respond({:ok, request}, conn)
    else
      {:error, :transaction_request_not_found} ->
        respond({:error, :unauthorized}, conn)

      error ->
        respond(error, conn)
    end
  end

  def get(conn, _),
    do:
      handle_error(
        conn,
        :invalid_parameter,
        "Invalid parameter provided. `formatted_id` is required."
      )

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    attrs
    |> Map.put("originator", Originator.extract(conn.assigns))
    |> Map.put("creator", conn.assigns)
    |> TransactionRequestGate.create()
    |> respond(conn)
  end

  # Respond with a list of transaction requests
  defp respond_multiple(%Paginator{} = paged_transaction_requests, conn) do
    render(conn, :transaction_requests, %{transaction_requests: paged_transaction_requests})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_multiple({:error, code}, conn) do
    handle_error(conn, code)
  end

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)

  defp respond({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond({:error, error}, conn) do
    handle_error(conn, error)
  end

  defp respond({:ok, request}, conn) do
    render(conn, :transaction_request, %{
      transaction_request: request
    })
  end

  @spec authorize(
          :all | :create | :get | :update,
          map(),
          String.t() | %Account{} | %TransactionRequest{} | nil
        ) :: :ok | {:error, any()} | no_return()
  defp authorize(action, actor, %Account{} = account) do
    AccountPolicy.authorize(action, actor, account)
  end

  defp authorize(action, actor, request) do
    TransactionRequestPolicy.authorize(action, actor, request)
  end
end
