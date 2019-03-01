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

defmodule EWalletAPI.V1.TransactionRequestController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler

  alias EWallet.{
    TransactionRequestFetcher,
    TransactionRequestGate,
    TransactionRequestPolicy,
    Web.Originator
  }

  @spec create_for_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_for_user(conn, attrs) do
    attrs = Map.put(attrs, "originator", Originator.extract(conn.assigns))

    conn.assigns.end_user
    |> TransactionRequestGate.create(attrs)
    |> respond(conn)
  end

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"formatted_id" => formatted_id}) do
    with {:ok, request} <- TransactionRequestFetcher.get(formatted_id),
         {:ok, _} <- authorize(:get, conn.assigns, request) do
      respond({:ok, request}, conn)
    else
      {:error, :transaction_request_not_found} ->
        respond({:error, :unauthorized}, conn)

      error ->
        respond(error, conn)
    end
  end

  def get(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter provided. `formatted_id` is required."
    )
  end

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)

  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond({:ok, request}, conn) do
    render(conn, :transaction_request, %{
      transaction_request: request
    })
  end

  @spec authorize(:all | :create | :get | :update, map(), %EWalletDB.TransactionRequest{}) ::
          :ok | {:error, any()} | no_return()
  defp authorize(action, params, request) do
    TransactionRequestPolicy.authorize(action, params, request)
  end
end
