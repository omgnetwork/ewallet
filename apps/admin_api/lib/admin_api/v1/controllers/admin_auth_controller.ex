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

defmodule AdminAPI.V1.AdminAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminUserAuthenticator
  alias EWallet.AccountPolicy
  alias EWallet.Web.{Orchestrator, Originator, V1.AuthTokenOverlay}
  alias EWalletDB.{Account, AuthToken, User}

  @doc """
  Authenticates a user with the given email and password.
  Returns with a newly generated authentication token if auth is successful.
  """
  def login(conn, attrs) do
    with email when is_binary(email) <- attrs["email"] || {:error, :missing_email},
         password when is_binary(password) <- attrs["password"] || {:error, :missing_password},
         conn <- AdminUserAuthenticator.authenticate(conn, attrs["email"], attrs["password"]),
         true <- conn.assigns.authenticated || {:error, :invalid_login_credentials},
         true <- User.get_status(conn.assigns.admin_user) == :active || {:error, :invite_pending},
         originator <- Originator.extract(conn.assigns),
         {:ok, auth_token} = AuthToken.generate(conn.assigns.admin_user, :admin_api, originator),
         {:ok, auth_token} <- Orchestrator.one(auth_token, AuthTokenOverlay, attrs) do
      render_token(conn, auth_token)
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)
    end
  end

  def switch_account(conn, %{"account_id" => account_id} = attrs) do
    with {:ok, _current_user} <- permit(:get, conn.assigns),
         %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         %{authorized: true} <- permit_account(:get, conn.assigns, account.id),
         token <- conn.private.auth_auth_token,
         %AuthToken{} = token <-
           AuthToken.get_by_token(token, :admin_api) || {:error, :auth_token_not_found},
         originator <- Originator.extract(conn.assigns),
         {:ok, token} <- AuthToken.switch_account(token, account, originator),
         {:ok, token} <- Orchestrator.one(token, AuthTokenOverlay, attrs) do
      render_token(conn, token)
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)
    end
  end

  def switch_account(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp render_token(conn, auth_token) do
    render(conn, :auth_token, %{auth_token: auth_token})
  end

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, _attrs) do
    with {:ok, _current_user} <- permit(:update, conn.assigns),
         originator <- Originator.extract(conn.assigns) do
      conn
      |> AdminUserAuthenticator.expire_token(originator)
      |> render(:empty_response, %{})
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @spec permit(:get | :update, map()) ::
          {:ok, %EWalletDB.User{}} | {:error, :access_key_unauthorized}
  defp permit(_action, %{admin_user: admin_user}) do
    {:ok, admin_user}
  end

  defp permit(_action, %{key: _key}) do
    {:error, :access_key_unauthorized}
  end

  defp permit_account(action, params, account_id) do
    Bodyguard.permit(AccountPolicy, action, params, account_id)
  end
end
