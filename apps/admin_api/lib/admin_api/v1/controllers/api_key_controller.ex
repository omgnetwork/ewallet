# Copyright 2019 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.APIKeyController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.Changeset
  alias EWallet.APIKeyPolicy
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.APIKeyOverlay}
  alias EWalletDB.APIKey

  @doc """
  Retrieves a list of API keys.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil) do
      APIKey.query_all()
      |> Orchestrator.query(APIKeyOverlay, attrs)
      |> respond_multiple(conn)
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  # Respond with a list of API keys
  defp respond_multiple(%Paginator{} = paginated, conn) do
    render(conn, :api_keys, %{api_keys: paginated})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @doc """
  Creates a new API key. Currently API keys are assigned to the master account only.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         # Admin API doesn't use API Keys anymore. Defaulting to "ewallet_api".
         {:ok, api_key} <-
           APIKey.insert(%{
             owner_app: "ewallet_api",
             originator: Originator.extract(conn.assigns)
           }),
         {:ok, api_key} <- Orchestrator.one(api_key, APIKeyOverlay, attrs) do
      render(conn, :api_key, %{api_key: api_key})
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Update an API key.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:update, conn.assigns, id),
         %APIKey{} = api_key <- APIKey.get(id) || {:error, :api_key_not_found},
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, api_key} <- APIKey.update(api_key, attrs),
         {:ok, api_key} <- Orchestrator.one(api_key, APIKeyOverlay, attrs) do
      render(conn, :api_key, %{api_key: api_key})
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  def update(conn, _attrs) do
    handle_error(conn, :invalid_parameter, "`id` is required")
  end

  @doc """
  Update an API key.
  """
  @spec enable_or_disable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def enable_or_disable(conn, %{"id" => id, "enabled" => _} = attrs) do
    with :ok <- permit(:enable_or_disable, conn.assigns, id),
         %APIKey{} = api_key <- APIKey.get(id) || {:error, :api_key_not_found},
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, api_key} <- APIKey.enable_or_disable(api_key, attrs),
         {:ok, api_key} <- Orchestrator.one(api_key, APIKeyOverlay, attrs) do
      render(conn, :api_key, %{api_key: api_key})
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  def enable_or_disable(conn, _attrs) do
    handle_error(conn, :invalid_parameter, "`id` and `enabled` are required")
  end

  @doc """
  Soft-deletes an existing API key by its id.
  """
  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with :ok <- permit(:delete, conn.assigns, id),
         %APIKey{} = key <- APIKey.get(id) do
      do_delete(conn, key)
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :api_key_not_found)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  defp do_delete(conn, %APIKey{} = key) do
    originator = Originator.extract(conn.assigns)

    case APIKey.delete(key, originator) do
      {:ok, _key} ->
        render(conn, :empty_response)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  @spec permit(
          :all | :create | :get | :update | :enable_or_disable | :delete,
          map(),
          String.t() | nil
        ) :: :ok | {:error, any()} | no_return()
  defp permit(action, params, api_key_id) do
    Bodyguard.permit(APIKeyPolicy, action, params, api_key_id)
  end
end
