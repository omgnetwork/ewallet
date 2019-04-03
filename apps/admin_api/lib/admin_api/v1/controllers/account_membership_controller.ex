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

defmodule AdminAPI.V1.AccountMembershipController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.{
    AccountMembershipPolicy,
    AdminUserPolicy,
    AccountPolicy,
    KeyPolicy,
    Bouncer.Permission,
    UserGate
  }

  alias EWallet.Web.{Orchestrator, Paginator, Originator, V1.MembershipOverlay}
  alias EWalletDB.{Account, Key, Membership, Role, User}

  @doc """
  Lists the memberships for the given admin.
  """
  def all_account_memberships_for_admin(conn, %{"id" => admin_id} = attrs) do
    with %User{} = admin <- User.get_admin(admin_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, admin),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized},
         query <- Membership.query_all_by_user(admin, query),
         %Paginator{} = memberships <- Orchestrator.query(query, MembershipOverlay, attrs) do
      render(conn, :memberships, %{memberships: memberships})
    else
      {:error, error} ->
        handle_error(conn, error)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  def all_account_memberships_for_admin(conn, _), do: handle_error(conn, :missing_id)

  @doc """
  Lists the memberships for the given key.
  """
  def all_account_memberships_for_key(conn, %{"id" => key_id} = attrs) do
    with %Key{} = key <- Key.get(key_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, key),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized},
         query <- Membership.query_all_by_key(key, query),
         %Paginator{} = memberships <- Orchestrator.query(query, MembershipOverlay, attrs) do
      render(conn, :memberships, %{memberships: memberships})
    else
      {:error, error} ->
        handle_error(conn, error)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  def all_account_memberships_for_key(conn, _), do: handle_error(conn, :missing_id)

  @doc """
  Lists the admin memberships for the given account.
  """
  def all_admin_memberships_for_account(conn, attrs) do
    all_for_account(conn, attrs, :user)
  end

  @doc """
  Lists the key memberships for the given account.
  """
  def all_key_memberships_for_account(conn, attrs) do
    all_for_account(conn, attrs, :key)
  end

  defp all_for_account(conn, %{"id" => account_id} = attrs, type) do
    with %Account{} = account <-
           Account.get(account_id, preload: [memberships: [type, :role]]) ||
             {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, %{query: query}} <- authorize(:all, conn.assigns, nil),
         true <- !is_nil(query) || {:error, :unauthorized},
         query <- query_members(account, query, type),
         %Paginator{} = memberships <- Orchestrator.query(query, MembershipOverlay, attrs) do
      render(conn, :memberships, %{memberships: memberships})
    else
      {:error, error} ->
        handle_error(conn, error)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  defp all_for_account(conn, _, _), do: handle_error(conn, :missing_id)

  defp query_members(account, query, :user) do
    Membership.query_all_users_by_account(account, query)
  end

  defp query_members(account, query, :key) do
    Membership.query_all_keys_by_account(account, query)
  end

  @doc """
  Assigns the key to the given account and role.
  """
  def assign_key(conn, %{"key_id" => key_id, "account_id" => account_id, "role_name" => role_name}) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         %Key{} = key <- Key.get(key_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, _} <- authorize(:get, conn.assigns, key),
         {:ok, _} <-
           authorize(:create, conn.assigns, %Membership{
             account: account,
             account_uuid: account.uuid
           }),
         %Role{} = role <-
           Role.get_by(name: role_name) || {:error, :role_name_not_found},
         originator <- Originator.extract(conn.assigns),
         {:ok, _} = Membership.assign(key, account, role, originator) do
      render(conn, :empty, %{success: true})
    else
      {:error, code} ->
        handle_error(conn, code)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  def assign_key(conn, _),
    do:
      handle_error(
        conn,
        :invalid_parameter,
        "`key_id`, `account_id` and `role_name` are required."
      )

  @doc """
  Unassigns the key to the given account and role.
  """
  def unassign_key(conn, %{
        "key_id" => key_id,
        "account_id" => account_id
      })
      when not is_nil(account_id) and not is_nil(key_id) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         %Key{} = key <- Key.get(key_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, key),
         %Membership{} = membership <-
           Membership.get_by_member_and_account(key, account) || {:error, :unauthorized},
         {:ok, _} <- authorize(:delete, conn.assigns, membership),
         originator <- Originator.extract(conn.assigns),
         {:ok, _} <- Membership.unassign(key, account, originator) do
      render(conn, :empty, %{success: true})
    else
      nil -> handle_error(conn, :unauthorized)
      {:error, error} -> handle_error(conn, error)
    end
  end

  def unassign_key(conn, _attrs),
    do: handle_error(conn, :invalid_parameter, "`key_id` and `account_id` are required.")

  @doc """
  Assigns the user to the given account and role.
  """
  def assign_user(conn, attrs) do
    with %Account{} = account <- Account.get(attrs["account_id"]) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         {:ok, _} <- authorize(:create, conn.assigns, %User{}),
         {:ok, _} <-
           authorize(:create, conn.assigns, %Membership{
             account: account,
             account_uuid: account.uuid
           }),
         {:ok, user_or_email} <- UserGate.get_user_or_email(attrs),
         %Role{} = role <-
           Role.get_by(name: attrs["role_name"]) || {:error, :role_name_not_found},
         {:ok, redirect_url} <- UserGate.validate_redirect_url(attrs["redirect_url"]),
         originator <- Originator.extract(conn.assigns),
         {:ok, _} <-
           UserGate.assign_or_invite(user_or_email, account, role, redirect_url, originator) do
      render(conn, :empty, %{success: true})
    else
      {true, :user_id_not_found} ->
        handle_error(conn, :user_id_not_found)

      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, %Permission{} = permission} ->
        handle_error(conn, permission)

      # Matches a different error format returned by Membership.assign_user/2
      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  @doc """
  Unassigns the user from the given account.
  """
  def unassign_user(conn, %{
        "user_id" => user_id,
        "account_id" => account_id
      })
      when not is_nil(account_id) and not is_nil(user_id) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, account),
         %User{} = user <- User.get(user_id) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user),
         %Membership{} = membership <-
           Membership.get_by_member_and_account(user, account) || {:error, :unauthorized},
         {:ok, _} <- authorize(:delete, conn.assigns, membership),
         originator <- Originator.extract(conn.assigns),
         {:ok, _} <- Membership.unassign(user, account, originator) do
      render(conn, :empty, %{success: true})
    else
      nil -> handle_error(conn, :unauthorized)
      {:error, error} -> handle_error(conn, error)
    end
  end

  def unassign_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  @spec authorize(:all | :create | :get | :update | :delete, map(), map()) ::
          {:ok, %Permission{}} | {:error, %Permission{}} | no_return()
  defp authorize(action, actor, %Account{} = account) do
    AccountPolicy.authorize(action, actor, account)
  end

  defp authorize(action, actor, %User{} = user) do
    AdminUserPolicy.authorize(action, actor, user)
  end

  defp authorize(action, actor, %Key{} = key) do
    KeyPolicy.authorize(action, actor, key)
  end

  defp authorize(action, actor, membership) do
    AccountMembershipPolicy.authorize(action, actor, membership)
  end
end
