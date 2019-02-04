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

defmodule AdminAPI.V1.RoleController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.RolePolicy
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.RoleOverlay}
  alias EWalletDB.Role

  @doc """
  Retrieves a list of roles.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         %Paginator{} = paginator <- Orchestrator.query(Role, RoleOverlay, attrs) do
      render(conn, :roles, %{roles: paginator})
    else
      {:error, code, description} ->
        handle_error(conn, code, description)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Retrieves a specific role by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:get, conn.assigns, id),
         %Role{} = role <- Role.get_by(id: id),
         {:ok, role} <- Orchestrator.one(role, RoleOverlay, attrs) do
      render(conn, :role, %{role: role})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :role_id_not_found)
    end
  end

  def get(conn, _), do: handle_error(conn, :missing_id)

  @doc """
  Creates a new role.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, role} <- Role.insert(attrs),
         {:ok, role} <- Orchestrator.one(role, RoleOverlay, attrs) do
      render(conn, :role, %{role: role})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Updates the role if all required parameters are provided.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:update, conn.assigns, id),
         %Role{} = original <- Role.get(id) || {:error, :role_id_not_found},
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- Role.update(original, attrs),
         {:ok, updated} <- Orchestrator.one(updated, RoleOverlay, attrs) do
      render(conn, :role, %{role: updated})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Soft-deletes an existing role by its id.
  """
  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:delete, conn.assigns, id),
         %Role{} = role <- Role.get(id) || {:error, :role_id_not_found},
         originator <- Originator.extract(conn.assigns),
         {:ok, deleted} <- Role.delete(role, originator),
         {:ok, deleted} <- Orchestrator.one(deleted, RoleOverlay, attrs) do
      render(conn, :role, %{role: deleted})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec permit(:all | :create | :get | :update | :delete, map(), String.t() | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, role_id) do
    Bodyguard.permit(RolePolicy, action, params, role_id)
  end
end
