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

defmodule AdminAPI.V1.UserController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias Ecto.Changeset
  alias EWallet.{UserPolicy, UserFetcher}
  alias EWallet.Web.{Originator, Orchestrator, Paginator, V1.UserOverlay}
  alias EWalletDB.{Account, AccountUser, User, UserQuery, AuthToken}

  @doc """
  Retrieves a list of users.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil) do
      # Get all users since everyone can access them
      User
      |> UserQuery.where_end_user()
      |> do_all(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account) do
      User
      |> UserQuery.where_end_user()
      |> Account.query_all_users([account.uuid])
      |> do_all(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account) do
      User
      |> UserQuery.where_end_user()
      |> Account.query_all_users(descendant_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec do_all(Ecto.Queryable.t(), map(), Plug.Conn.t()) :: Plug.Conn.t()
  defp do_all(query, attrs, conn) do
    query
    |> Orchestrator.query(UserOverlay, attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific user by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id}) do
    with %User{} = user <- User.get(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, user) do
      respond_single(user, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def get(conn, %{"provider_user_id" => id})
      when is_binary(id) and byte_size(id) > 0 do
    with %User{} = user <- User.get_by_provider_user_id(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, user) do
      respond_single(user, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def get(conn, _params) do
    handle_error(conn, :invalid_parameter)
  end

  # When creating a new user, we need to link it with the current account
  # defined in the key or in the auth token so that the user can access it
  # even if that user hasn't had any transaction with the account yet (since
  # that's how users and accounts are linked together).
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         originator <- Originator.extract(conn.assigns),
         attrs <- Map.put(attrs, "originator", originator),
         {:ok, user} <- User.insert(attrs),
         %Account{} = account <- AccountHelper.get_current_account(conn),
         {:ok, _account_user} <- AccountUser.link(account.uuid, user.uuid, originator) do
      respond_single(user, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  @doc """
  Updates the user if all required parameters are provided.
  """
  # Pattern matching for required params because changeset will treat
  # missing param as not need to update.
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(
        conn,
        %{
          "id" => id,
          "username" => _
        } = attrs
      )
      when is_binary(id) and byte_size(id) > 0 do
    with %User{} = user <- User.get(id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, user),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns) do
      user
      |> User.update(attrs)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def update(
        conn,
        %{
          "provider_user_id" => id,
          "username" => _
        } = attrs
      )
      when is_binary(id) and byte_size(id) > 0 do
    with %User{} = user <- User.get_by_provider_user_id(id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, user),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns) do
      user
      |> User.update(attrs)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def update(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  @doc """
  Enable or disable a user.
  """
  @spec enable_or_disable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def enable_or_disable(conn, attrs) do
    with {:ok, %User{} = user} <- UserFetcher.fetch(attrs),
         :ok <- permit(:enable_or_disable, conn.assigns, user),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- User.enable_or_disable(user, attrs),
         :ok <- AuthToken.expire_for_user(updated) do
      respond_single(updated, conn)
    else
      {:error, :invalid_parameter = error} ->
        handle_error(
          conn,
          error,
          "Invalid parameter provided. `id` or `provider_user_id` is required."
        )

      {:error, error} ->
        handle_error(conn, error)
    end
  end

  # Respond with a list of users
  defp respond_multiple(%Paginator{} = paged_users, conn) do
    render(conn, :users, %{users: paged_users})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single user
  defp respond_single(%User{} = user, conn), do: render(conn, :user, %{user: user})

  # Responds when the user is not found
  defp respond_single(nil, conn), do: handle_error(conn, :user_id_not_found)

  # Responds when user is saved successfully
  defp respond_single({:ok, user}, conn) do
    respond_single(user, conn)
  end

  defp respond_single({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:error, code}, conn) do
    handle_error(conn, code)
  end

  @spec permit(:all | :create | :get | :update, map(), %Account{} | %User{} | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, user) do
    Bodyguard.permit(UserPolicy, action, params, user)
  end
end
