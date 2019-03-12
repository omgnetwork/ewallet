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

defmodule AdminAPI.V1.TokenController do
  @moduledoc """
  The controller to serve token endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.{Changeset}
  alias EWallet.{Helper, MintGate, TokenPolicy, MintPolicy, AdapterHelper}
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.TokenOverlay}
  alias EWalletDB.{Account, Mint, Token}
  alias Ecto.Changeset

  @doc """
  Retrieves a list of tokens.
  """
  @spec all(Plug.Conn.t(), map() | nil) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query
      |> Orchestrator.query(TokenOverlay, attrs)
      |> respond_multiple(conn)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Retrieves a specific token by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id}) do
    with %Token{} = token <- Token.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, token) do
      respond_single(token, conn)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Retrieves stats for a specific token.
  """
  @spec stats(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def stats(conn, %{"id" => id}) do
    with %Token{} = token <- Token.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:stats, conn.assigns, token) do
      stats = %{
        token: token,
        total_supply: Mint.total_supply_for_token(token)
      }

      render(conn, :stats, %{stats: stats})
    else
      {:error, code} ->
        handle_error(conn, code)

      error ->
        handle_error(conn, error)
    end
  end

  def stats(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Creates a new Token.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with attrs <- Map.put(attrs, "account_uuid", Account.get_master_account().uuid),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, _} <- authorize(:create, conn.assigns, attrs) do
      do_create(conn, attrs)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  defp do_create(conn, %{"amount" => amount} = attrs) when is_number(amount) and amount > 0 do
    with {:ok, token} <- Token.insert(attrs),
         {:ok, _} <-
           authorize(:create, conn.assigns, %Mint{token_uuid: token.uuid, token: token}) || token do
      token
      |> MintGate.mint_token(%{
        "amount" => amount,
        "originator" => Originator.extract(conn.assigns)
      })
      |> respond_single(conn)
    else
      %Token{} = token ->
        respond_single(token, conn)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  defp do_create(conn, %{"amount" => amount} = attrs) when is_binary(amount) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} ->
        attrs =
          attrs
          |> Map.put("amount", amount)
          |> Originator.set_in_attrs(conn.assigns)

        create(conn, attrs)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  defp do_create(conn, attrs) do
    case attrs["amount"] do
      nil ->
        attrs
        |> Map.put("account_uuid", Account.get_master_account().uuid)
        |> Originator.set_in_attrs(conn.assigns)
        |> Token.insert()
        |> respond_single(conn)

      amount ->
        handle_error(conn, :invalid_parameter, "Invalid amount provided: '#{amount}'.")
    end
  end

  @doc """
  Update an existing Token.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = attrs) do
    with %Token{} = token <- Token.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:update, conn.assigns, token),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- Token.update(token, attrs) do
      respond_single(updated, conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  def update(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `id` is required.")
  end

  @doc """
  Enable or disable a token.
  """
  @spec enable_or_disable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def enable_or_disable(conn, %{"id" => id} = attrs) do
    with %Token{} = token <- Token.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:enable_or_disable, conn.assigns, token),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- Token.enable_or_disable(token, attrs) do
      respond_single(updated, conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  def enable_or_disable(conn, _),
    do: handle_error(conn, :invalid_parameter, "Invalid parameter provided. `id` is required.")

  @doc """
  Uploads an image as avatar for a specific token.
  """
  @spec upload_avatar(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def upload_avatar(conn, %{"id" => id, "avatar" => _} = attrs) do
    with %Token{} = token <- Token.get(id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, token.id),
         :ok <- AdapterHelper.check_adapter_status(),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         %{} = saved <- Token.store_avatar(token, attrs),
         {:ok, saved} <- Orchestrator.one(saved, TokenOverlay, attrs) do
      render(conn, :token, %{token: saved})
    else
      nil ->
        handle_error(conn, :invalid_parameter)

      %Changeset{} = changeset ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def upload_avatar(conn, _),
    do: handle_error(conn, :invalid_parameter, "`id` and `avatar` are required")

  # Respond with a list of tokens
  defp respond_multiple(%Paginator{} = paged_tokens, conn) do
    render(conn, :tokens, %{tokens: paged_tokens})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_multiple({:error, code}, conn) do
    handle_error(conn, code)
  end

  # Respond with a single token
  defp respond_single({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:error, code}, conn) do
    handle_error(conn, code)
  end

  defp respond_single({:ok, _mint, token}, conn) do
    render(conn, :token, %{token: token})
  end

  defp respond_single({:ok, token}, conn) do
    render(conn, :token, %{token: token})
  end

  defp respond_single(%Token{} = token, conn) do
    render(conn, :token, %{token: token})
  end

  defp respond_single(nil, conn) do
    handle_error(conn, :token_not_found)
  end

  defp respond_single(error_code, conn) when is_atom(error_code) do
    handle_error(conn, error_code)
  end

  @spec authorize(:create, map(), String.t() | nil) :: any()
  defp authorize(:create = action, actor, %Mint{} = mint) do
    MintPolicy.authorize(action, actor, mint)
  end

  @spec authorize(:all | :create | :get | :update, map(), String.t() | nil) :: any()
  defp authorize(action, actor, token_attrs) do
    TokenPolicy.authorize(action, actor, token_attrs)
  end
end
