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

defmodule AdminAPI.V1.KeyController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.KeyPolicy
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.KeyOverlay}
  alias EWalletDB.Key
  alias Ecto.Changeset

  @doc """
  Retrieves a list of keys.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query
      |> Orchestrator.query(KeyOverlay, attrs)
      |> respond_multiple(conn)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  # Respond with a list of keys
  defp respond_multiple(%Paginator{} = paginated_keys, conn) do
    render(conn, :keys, %{keys: paginated_keys})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @doc """
  Creates a new key. Currently keys are assigned to the master account only.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with {:ok, _} <- authorize(:create, conn.assigns, attrs),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns, :originator),
         {:ok, key} <- Key.insert(attrs),
         {:ok, key} <- Orchestrator.one(key, KeyOverlay, attrs) do
      render(conn, :key, %{key: key})
    else
      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Updates a key. (Deprecated)
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = attrs) do
    with %Key{} = key <- Key.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:update, conn.assigns, key),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, key} <- Key.enable_or_disable(key, attrs),
         {:ok, key} <- Orchestrator.one(key, KeyOverlay, attrs) do
      render(conn, :key, %{key: key})
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  def update(conn, _attrs) do
    handle_error(conn, :invalid_parameter, "`id` is required")
  end

  @doc """
  Enable or disable a key.
  """
  @spec enable_or_disable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def enable_or_disable(conn, %{"id" => id, "enabled" => _} = attrs) do
    with %Key{} = key <- Key.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:enable_or_disable, conn.assigns, key),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, key} <- Key.enable_or_disable(key, attrs),
         {:ok, key} <- Orchestrator.one(key, KeyOverlay, attrs) do
      render(conn, :key, %{key: key})
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  def enable_or_disable(conn, _attrs) do
    handle_error(conn, :invalid_parameter, "`id` and `enabled` are required")
  end

  @doc """
  Soft-deletes an existing key.
  """
  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"access_key" => access_key}) do
    with %Key{} = key <- Key.get_by(access_key: access_key) || {:error, :unauthorized},
         {:ok, _} <- authorize(:delete, conn.assigns, key) do
      do_delete(conn, key)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, %{"id" => id}) do
    with %Key{} = key <- Key.get(id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:delete, conn.assigns, key) do
      do_delete(conn, key)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  defp do_delete(conn, %Key{} = key) do
    originator = Originator.extract(conn.assigns)

    case Key.delete(key, originator) do
      {:ok, _key} ->
        render(conn, :empty_response)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  defp do_delete(conn, nil), do: handle_error(conn, :key_not_found)

  @spec authorize(
          :all | :create | :get | :update | :enable_or_disable | :delete,
          map(),
          String.t() | nil
        ) :: :ok | {:error, any()} | no_return()
  defp authorize(action, params, key) do
    KeyPolicy.authorize(action, params, key)
  end
end
