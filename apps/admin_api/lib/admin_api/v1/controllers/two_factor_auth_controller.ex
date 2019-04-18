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

defmodule AdminAPI.V1.TwoFactorAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminAPIAuth
  alias EWallet.{TwoFactorPolicy, TwoFactorAuthenticator}
  alias EWallet.Web.{Orchestrator, V1.AuthTokenOverlay}
  alias EWalletDB.{AuthToken, User}
  alias Ecto.Changeset

  def verify(conn, attrs) do
    with auth_params <- verify_user_authenticated(conn),
         {:ok, user} <- verify_user_2fa_enabled(auth_params),
         {:ok, _} <- authorize(:verify, auth_params, user),
         {:ok} <- TwoFactorAuthenticator.verify(attrs, user),
         {:ok, token} = AuthToken.generate_token(user, :admin_api, user),
         {:ok, token} <- Orchestrator.one(token, AuthTokenOverlay, attrs) do
      render(conn, :auth_token, %{auth_token: token})
    else
      error -> respond_error(error, conn)
    end
  end

  defp verify_user_authenticated(conn) do
    AdminAPIAuth.authenticate(%{headers: conn.req_headers})
  end

  defp verify_user_2fa_enabled(%{admin_user: admin_user}) do
    do_verify_user_2fa_enabled(admin_user)
  end

  defp verify_user_2fa_enabled(%{auth_error: error_code}) when is_atom(error_code) do
    {:error, error_code}
  end

  defp do_verify_user_2fa_enabled(%{enabled_2fa_at: nil}), do: {:error, :invalid_parameter}

  defp do_verify_user_2fa_enabled(%{enabled_2fa_at: _} = user), do: {:ok, user}

  def create_backup_codes(conn, _), do: do_create(conn, :backup_codes)

  def create_secret_code(conn, _), do: do_create(conn, :secret_code)

  defp do_create(conn, type) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         {:ok, _} <- authorize(:create, conn.assigns, user),
         {:ok, result} <- TwoFactorAuthenticator.create_and_update(user, type) do
      render(conn, :create, result)
    else
      error -> respond_error(error, conn)
    end
  end

  def enable(conn, attrs), do: do_enable(conn, attrs, true)

  def disable(conn, attrs), do: do_enable(conn, attrs, false)

  defp do_enable(conn, attrs, enable) do
    with %User{} = user <- conn.assigns[:admin_user] || {:error, :unauthorized},
         auth_token <- conn.private[:auth_auth_token],
         {:ok, _} <- authorize(:create, conn.assigns, user),
         {:ok} <- TwoFactorAuthenticator.verify(attrs, user),
         {:ok, token} <- TwoFactorAuthenticator.enable(user, auth_token, :admin_api, enable),
         {:ok, token} <- Orchestrator.one(token, AuthTokenOverlay, attrs) do
      render(conn, :auth_token, %{auth_token: token})
    else
      error -> respond_error(error, conn)
    end
  end

  defp respond_error({:error, error}, conn) when is_atom(error) do
    handle_error(conn, error)
  end

  defp respond_error({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_error({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp authorize(action, actor, target) do
    TwoFactorPolicy.authorize(action, actor, target)
  end
end
