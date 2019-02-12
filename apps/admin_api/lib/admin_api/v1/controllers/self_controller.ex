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
  alias EWallet.{Mailer, UpdateEmailGate, AdapterHelper}
  alias EWallet.Web.{Orchestrator, Originator, UrlValidator}
  alias EWallet.Web.V1.AccountOverlay
  alias EWalletDB.{Account, User}

  @doc """
  Retrieves the currently authenticated user.
  """
  def get(conn, _attrs) do
    with {:ok, current_user} <- permit(:get, conn.assigns) do
      render(conn, :user, %{user: current_user})
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Updates the user if all required parameters are provided.
  """
  def update(conn, attrs) do
    with {:ok, current_user} <- permit(:update, conn.assigns),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, user} <- User.update(current_user, attrs) do
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
    with {:ok, current_user} <- permit(:update_password, conn.assigns),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, user} <- User.update_password(current_user, attrs) do
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
    with {:ok, user} <- permit(:update_email, conn.assigns),
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
    with %{authorized: true} <- permit(:verify_email, conn.assigns),
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
    with {:ok, current_user} <- permit(:update, conn.assigns),
         originator <- Originator.extract(conn.assigns),
         :ok <- AdapterHelper.check_adapter_status(),
         attrs <- Map.put(attrs, "originator", originator) do
      current_user
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
    with {:ok, current_user} <- permit(:update, conn.assigns),
         %Account{} = account <- User.get_account(current_user) || :user_account_not_found,
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
    with {:ok, current_user} <- permit(:update, conn.assigns),
         account_uuids <- AccountHelper.get_accessible_account_uuids(%{admin_user: current_user}) do
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

  @spec permit(:get | :update | :update_password | :update_email | :verify_email, map()) ::
          {:ok, %User{}} | {:error, :access_key_unauthorized}
  defp permit(:verify_email, _) do
    # verify_email action can be done unauthenticated
    :ok
  end

  defp permit(_action, %{admin_user: admin_user}) do
    {:ok, admin_user}
  end

  defp permit(_action, %{key: _key}) do
    {:error, :access_key_unauthorized}
  end
end
