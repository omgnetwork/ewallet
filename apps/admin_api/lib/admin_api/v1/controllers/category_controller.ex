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

defmodule AdminAPI.V1.CategoryController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.CategoryPolicy
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.CategoryOverlay}
  alias EWalletDB.Category

  @doc """
  Retrieves a list of categories.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         %Paginator{} = paginator <- Orchestrator.query(Category, CategoryOverlay, attrs) do
      render(conn, :categories, %{categories: paginator})
    else
      {:error, code, description} ->
        handle_error(conn, code, description)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Retrieves a specific category by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:get, conn.assigns, id),
         %Category{} = category <- Category.get_by(id: id),
         {:ok, category} <- Orchestrator.one(category, CategoryOverlay, attrs) do
      render(conn, :category, %{category: category})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :category_id_not_found)
    end
  end

  @doc """
  Creates a new category.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, category} <- Category.insert(attrs),
         {:ok, category} <- Orchestrator.one(category, CategoryOverlay, attrs) do
      render(conn, :category, %{category: category})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Updates the category if all required parameters are provided.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:update, conn.assigns, id),
         %Category{} = original <- Category.get(id) || {:error, :category_id_not_found},
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- Category.update(original, attrs),
         {:ok, updated} <- Orchestrator.one(updated, CategoryOverlay, attrs) do
      render(conn, :category, %{category: updated})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Soft-deletes an existing category by its id.
  """
  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:delete, conn.assigns, id),
         %Category{} = category <- Category.get(id) || {:error, :category_id_not_found},
         originator <- Originator.extract(conn.assigns),
         {:ok, deleted} <- Category.delete(category, originator),
         {:ok, deleted} <- Orchestrator.one(deleted, CategoryOverlay, attrs) do
      render(conn, :category, %{category: deleted})
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
  defp permit(action, params, account_id) do
    Bodyguard.permit(CategoryPolicy, action, params, account_id)
  end
end
