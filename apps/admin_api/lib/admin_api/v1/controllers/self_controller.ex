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

defmodule AdminAPI.V1.SelfController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.UpdateEmailAddressEmail
  alias AdminAPI.V1.{AccountHelper, AccountView, UserView}
  alias Bamboo.Email
  alias Ecto.Changeset
  alias EWallet.{Mailer, UpdateEmailGate, AdapterHelper, AdminUserPolicy}
  alias EWallet.Web.{Orchestrator, Originator, UrlValidator}
  alias EWallet.Web.V1.AccountOverlay
  alias EWalletDB.{Account, User}

  @doc """
  Retrieves the currently authenticated user.
  """
  def get(conn, _attrs) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, user) do
      respond_single(user, conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Updates the user if all required parameters are provided.
  """
  def update(conn, attrs) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:update, conn.assigns, user),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, user} <- User.update(user, attrs) do
      respond_single(user, conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Updates the user's password if all required parameters are provided.
  """
  def update_password(conn, attrs) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:update_password, conn.assigns, user),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, user} <- User.update_password(user, attrs) do
      respond_single(user, conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Initiates the user's email update flow.
  """
  @spec update_email(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update_email(conn, %{"email" => email, "redirect_url" => redirect_url})
      when not is_nil(email) and not is_nil(redirect_url) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:update_email, conn.assigns, user),
         {:ok, redirect_url} <- validate_redirect_url(redirect_url),
         {:ok, request} <- UpdateEmailGate.update(user, email),
         %Email{} = email <- UpdateEmailAddressEmail.create(request, redirect_url),
         %Email{} <- Mailer.deliver_now(email) do
      respond_single(user, conn)
    else
      {:error, code} ->
        handle_error(conn, code)

      {:error, code, meta} ->
        handle_error(conn, code, meta)
    end
  end

  def update_email(conn, _), do: handle_error(conn, :invalid_parameter)

  defp validate_redirect_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "redirect_url", url: url}
    end
  end

  @doc """
  Verifies the user's new email.
  """
  @spec verify_email(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify_email(
        conn,
        %{
          "email" => email,
          "token" => token
        }
      ) do
    with {:ok, _} <- authorize(:verify_email, nil, nil),
         {:ok, user} <- UpdateEmailGate.verify(email, token) do
      respond_single(user, conn)
    else
      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def verify_email(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Uploads an image as avatar for the current user.
  """
  def upload_avatar(conn, %{"avatar" => _} = attrs) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:upload_avatar, conn.assigns, user),
         originator <- Originator.extract(conn.assigns),
         :ok <- AdapterHelper.check_adapter_status(),
         attrs <- Map.put(attrs, "originator", originator) do
      user
      |> User.store_avatar(attrs)
      |> respond_single(conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  def upload_avatar(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Retrieves the upper-most account that the given user has membership in.
  """
  def get_account(conn, attrs) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:get_account, conn.assigns, user),
         %Account{} = account <- User.get_account(user) || :user_account_not_found,
         {:ok, account} <- Orchestrator.one(account, AccountOverlay, attrs) do
      render(conn, AccountView, :account, %{account: account})
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Retrieves the list of accounts that the authenticated user has membership in.
  """
  def get_accounts(conn, attrs) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, p} <- authorize(:get_accounts, conn.assigns, user),
         account_uuids <- AccountHelper.get_accessible_account_uuids(%{admin_user: user}) do
      accounts =
        Account
        |> Account.where_in(account_uuids)
        |> Orchestrator.query(AccountOverlay, attrs)

      render(conn, AccountView, :accounts, %{accounts: accounts})
    else
      error ->
        respond_single(error, conn)
    end
  end

  # Respond with a single admin
  defp respond_single({:ok, user}, conn) do
    render(conn, UserView, :user, %{user: user})
  end

  defp respond_single(%User{} = user, conn) do
    render(conn, UserView, :user, %{user: user})
  end

  # Responds when the given params were invalid
  defp respond_single({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:error, error_code}, conn) when is_atom(error_code) do
    handle_error(conn, error_code)
  end

  defp respond_single(error_code, conn) when is_atom(error_code) do
    handle_error(conn, error_code)
  end

  # Responds when the admin is not found
  defp respond_single(nil, conn) do
    handle_error(conn, :user_id_not_found)
  end

  @spec authorize(
          :get
          | :update
          | :update_password
          | :update_email
          | :verify_email
          | :upload_avatar
          | :get_account
          | :get_accounts,
          map(),
          String.t() | nil
        ) ::
          :ok | {:error, any()} | no_return()
  # verify_email action can be done unauthenticated
  defp authorize(:verify_email, _actor, _target), do: {:ok, nil}

  defp authorize(action, %{admin_user: admin_user} = actor, target) do
    AdminUserPolicy.authorize(action, actor, target)
  end

  defp authorize(_action, %{key: _key}, _target), do: {:error, :unauthorized}
end
