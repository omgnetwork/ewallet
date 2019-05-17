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

defmodule AdminAPI.V1.ExchangePairController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{ExchangePairGate, ExchangePairPolicy}
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.ExchangePairOverlay}
  alias EWalletDB.ExchangePair
  alias Ecto.Changeset

  @doc """
  Retrieves a list of exchange pairs.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized},
         %Paginator{} = paginator <- Orchestrator.query(query, ExchangePairOverlay, attrs),
         %Paginator{} = paginator <- ExchangePairGate.add_opposite_pairs(paginator) do
      render(conn, :exchange_pairs, %{exchange_pairs: paginator})
    else
      {:error, code, description} ->
        handle_error(conn, code, description)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Retrieves a specific exchange pair by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id}) do
    with %ExchangePair{} = pair <- ExchangePair.get_by(id: id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, pair),
         {:ok, pair} <- Orchestrator.one(pair, ExchangePairOverlay),
         pair <- ExchangePairGate.add_opposite_pair(pair) do
      render(conn, :exchange_pair, %{exchange_pair: pair})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :exchange_pair_id_not_found)
    end
  end

  def get(conn, _), do: handle_error(conn, :missing_id)

  @doc """
  Creates a new exchange pair.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with {:ok, _} <- authorize(:create, conn.assigns, attrs),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, pairs} <- ExchangePairGate.insert(attrs),
         {:ok, pairs} <- Orchestrator.all(pairs, ExchangePairOverlay),
         pairs <- ExchangePairGate.add_opposite_pairs(pairs) do
      render(conn, :exchange_pairs, %{exchange_pairs: pairs})
    else
      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  @doc """
  Updates the exchange pair if all required parameters are provided.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = attrs) do
    with %ExchangePair{} = pair <- ExchangePair.get_by(id: id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:update, conn.assigns, pair),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, pairs} <- ExchangePairGate.update(id, attrs),
         {:ok, pairs} <- Orchestrator.all(pairs, ExchangePairOverlay),
         pairs <- ExchangePairGate.add_opposite_pairs(pairs) do
      render(conn, :exchange_pairs, %{exchange_pairs: pairs})
    else
      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Soft-deletes an existing exchange pair by its id.
  """
  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id} = attrs) do
    with %ExchangePair{} = pair <- ExchangePair.get_by(id: id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:delete, conn.assigns, pair),
         originator <- Originator.extract(conn.assigns),
         {:ok, deleted_pairs} <- ExchangePairGate.delete(id, attrs, originator),
         {:ok, deleted_pairs} <- Orchestrator.all(deleted_pairs, ExchangePairOverlay),
         deleted_pairs <- ExchangePairGate.add_opposite_pairs(deleted_pairs) do
      render(conn, :exchange_pairs, %{exchange_pairs: deleted_pairs})
    else
      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec authorize(:all | :create | :get | :update | :delete, map(), String.t() | nil) ::
          :ok | {:error, any()} | no_return()
  defp authorize(action, actor, exchange_pair) do
    ExchangePairPolicy.authorize(action, actor, exchange_pair)
  end
end
