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

defmodule AdminAPI.V1.MintController do
  @moduledoc """
  The controller to serve mint endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.Changeset
  alias EWallet.{MintGate, MintPolicy}
  alias EWallet.Web.{Originator, Orchestrator, Paginator, V1.MintOverlay}
  alias EWalletDB.{Mint, Token}
  alias Plug.Conn

  @doc """
  Retrieves a list of mints.
  """
  @spec all_for_token(Conn.t(), map() | nil) :: Conn.t()
  def all_for_token(conn, %{"id" => id} = attrs) do
    with %{authorized: true} <- permit(:all, conn.assigns, nil),
         %Token{} = token <- Token.get(id) || :token_not_found,
         mints <- Mint.query_by_token(token),
         %Paginator{} = paged_mints <- Orchestrator.query(mints, MintOverlay, attrs) do
      render(conn, :mints, %{mints: paged_mints})
    else
      error -> handle_mint_error(conn, error)
    end
  end

  def all_for_token(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Mint a token.
  """
  @spec mint(Conn.t(), map()) :: Conn.t()
  def mint(
        conn,
        %{
          "id" => token_id,
          "amount" => _
        } = attrs
      ) do
    with %Token{} = token <- Token.get(token_id) || :unauthorized,
         %{authorized: true} <-
           permit(:create, conn.assigns, %Mint{token_uuid: token.uuid, token: token}),
         originator <- Originator.extract(conn.assigns),
         attrs <- Map.put(attrs, "originator", originator),
         {:ok, mint, _token} <- MintGate.mint_token(token, attrs),
         {:ok, mint} <- Orchestrator.one(mint, MintOverlay, attrs) do
      render(conn, :mint, %{mint: mint})
    else
      error -> handle_mint_error(conn, error)
    end
  end

  def mint(conn, _), do: handle_error(conn, :invalid_parameter)

  defp handle_mint_error(conn, {:error, code, description}) do
    handle_error(conn, code, description)
  end

  defp handle_mint_error(conn, {:error, %Changeset{} = changeset}) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp handle_mint_error(conn, {:error, code}) do
    handle_error(conn, code)
  end

  defp handle_mint_error(conn, error) do
    handle_error(conn, error)
  end

  @spec permit(:all | :create | :get | :update, map(), String.t() | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, account_id) do
    Bodyguard.permit(MintPolicy, action, params, account_id)
  end
end
