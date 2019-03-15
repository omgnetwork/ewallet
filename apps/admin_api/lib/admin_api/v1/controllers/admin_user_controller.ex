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

defmodule AdminAPI.V1.AdminUserController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.UpdateEmailAddressEmail
  alias AdminAPI.V1.AdminUserView
  alias Bamboo.Email
  alias EWallet.{Mailer, AdminUserPolicy, UserFetcher, UpdateEmailGate, UserGate}
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.UserOverlay}
  alias EWalletDB.{User, AuthToken}

  @doc """
  Retrieves a list of admins that the current user/key has access to.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized} do
      query
      |> User.query_admin_users()
      |> Orchestrator.query(UserOverlay, attrs)
      |> respond_multiple(conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  @doc """
  Retrieves a specific admin by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => user_id}) do
    with %User{} = user <- User.get_admin(user_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user) do
      respond_single(user, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def get(conn, _), do: handle_error(conn, :missing_id)

  @doc """
  Creates a new admin user.

  The requesting user must have the permissions to create admin users.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"email" => email, "redirect_url" => redirect_url} = attrs)
      when not is_nil(email) and not is_nil(redirect_url) do
    with {:ok, _} <- authorize(:create, conn.assigns, %User{global_role: attrs["global_role"]}),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         attrs <- Map.put(attrs, "is_admin", true),
         {:ok, user_or_email} <- UserGate.get_user_or_email(attrs),
         {:ok, redirect_url} <- UserGate.validate_redirect_url(redirect_url),
         {:ok, _invite} <- UserGate.invite_global_user(attrs, redirect_url) do
      render(conn, :empty, %{success: true})
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def create(conn, _attrs),
    do: handle_error(conn, :invalid_parameter, "`redirect_url` is required.")

  @doc """
  Updates a new admin user.

  The requesting user must have the permissions to update admin users.
  Admin users can't update themselves through this endpoint.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => user_id} = attrs) do
    with %User{} = original <- User.get(user_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:update, conn.assigns, original),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         true <- attrs["originator"].uuid != original.uuid || {:error, :unauthorized},
         {:ok, updated} <- User.update(original, attrs),
         {:ok, updated} <- update_email(updated, attrs),
         {:ok, updated} <- Orchestrator.one(updated, UserOverlay, attrs) do
      render(conn, :admin_user, %{admin_user: updated})
    else
      {:error, error} -> handle_error(conn, error)
      {:error, code, description} -> handle_error(conn, code, description)
    end
  end

  def update(conn, _), do: handle_error(conn, :invalid_parameter, "`id` is required.")

  defp update_email(user, %{"email" => email, "redirect_url" => redirect_url} = attrs)
       when not is_nil(email) and not is_nil(redirect_url) do
    with {:ok, redirect_url} <- UserGate.validate_redirect_url(redirect_url),
         {:ok, request} <- UpdateEmailGate.update(user, email),
         %Email{} = email <- UpdateEmailAddressEmail.create(request, redirect_url),
         %Email{} <- Mailer.deliver_now(email) do
      {:ok, user}
    else
      error ->
        error
    end
  end

  defp update_email(user, %{"email" => email} = attrs) when not is_nil(email) do
    {:error, :invalid_parameter,
     "A valid `redirect_url` is required when updating an admin user's email."}
  end

  defp update_email(user, _), do: {:ok, user}

  @doc """
  Enable or disable a user.
  """
  @spec enable_or_disable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def enable_or_disable(conn, attrs) do
    with {:ok, user} <- UserFetcher.fetch(attrs),
         {:ok, _} <- authorize(:enable_or_disable, conn.assigns, user),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- User.enable_or_disable(user, attrs),
         :ok <- AuthToken.expire_for_user(updated) do
      respond_single(updated, conn)
    else
      {:error, :invalid_parameter = error} ->
        handle_error(
          conn,
          error,
          "Invalid parameter provided. `id` is required."
        )

      {:error, error} ->
        handle_error(conn, error)
    end
  end

  # Respond with a list of admins
  defp respond_multiple(%Paginator{} = paged_users, conn) do
    render(conn, :admin_users, %{admin_users: paged_users})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_multiple({:error, code}, conn) do
    handle_error(conn, code)
  end

  # Respond with a single admin
  defp respond_single(%User{} = user, conn) do
    render(conn, :admin_user, %{admin_user: user})
  end

  @spec authorize(:all | :create | :get | :update, map(), %User{} | nil) ::
          :ok | {:error, any()} | no_return()
  defp authorize(action, actor, user) do
    AdminUserPolicy.authorize(action, actor, user)
  end
end
