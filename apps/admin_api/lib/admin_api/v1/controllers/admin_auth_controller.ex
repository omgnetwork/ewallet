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

defmodule AdminAPI.V1.AdminAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminUserAuthenticator
  alias EWallet.{AccountPolicy, AdminUserPolicy}
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
         {:ok, auth_token} <- generate_auth_token(conn.assigns.admin_user, originator),
         {:ok, auth_token} <- Orchestrator.one(auth_token, AuthTokenOverlay, attrs) do
      render_token(conn, auth_token)
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)
    end
  end

  defp generate_auth_token(%User{} = admin_user, originator) do
    if User.enabled_2fa?(admin_user) do
      AuthToken.generate_pre_token(admin_user, :admin_api, originator)
    else
      AuthToken.generate_token(admin_user, :admin_api, originator)
    end
  end

  def switch_account(conn, _attrs) do
    handle_error(conn, :unauthorized)
  end

  defp render_token(conn, auth_token) do
    render(conn, :auth_token, %{auth_token: auth_token})
  end

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, _attrs) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:logout, conn.assigns, user),
         originator <- Originator.extract(conn.assigns) do
      conn
      |> AdminUserAuthenticator.expire_token(originator)
      |> render(:empty_response, %{})
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @spec authorize(:switch_account | :logout, map(), String.t() | nil) ::
          {:ok, any()} | {:error, any()}
  defp authorize(action, actor, %Account{} = account) do
    AccountPolicy.authorize(action, actor, account)
  end

  defp authorize(action, %{admin_user: _admin_user} = actor, target) do
    AdminUserPolicy.authorize(action, actor, target)
  end

  defp authorize(_action, %{key: _key}, _target), do: {:error, :access_key_unauthorized}
end
