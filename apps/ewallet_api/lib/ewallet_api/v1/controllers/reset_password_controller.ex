# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.V1.ResetPasswordController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.{ForgetPasswordEmail, Mailer, ResetPasswordGate}
  alias EWallet.Web.UrlValidator

  @doc """
  Starts the reset password request flow for a user.

  This function is used when the eWallet is setup as a standalone solution,
  allowing users to reset their password without going through the integration
  with the provider's server.
  """
  @spec reset(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def reset(conn, %{"email" => email, "redirect_url" => redirect_url})
      when not is_nil(email) and not is_nil(redirect_url) do
    with {:ok, redirect_url} <- validate_redirect_url(redirect_url),
         {:ok, request} <- ResetPasswordGate.request(email),
         {:ok, _email} <- send_request_email(request, redirect_url) do
      render(conn, :empty, %{success: true})
    else
      # Prevents attackers from gaining knowledge about a user's email.
      {:error, :user_email_not_found} ->
        render(conn, :empty, %{success: true})

      {:error, code, meta} ->
        handle_error(conn, code, meta)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def reset(conn, _) do
    handle_error(conn, :invalid_parameter, "`email` and `redirect_url` are required")
  end

  defp validate_redirect_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "redirect_url", url: url}
    end
  end

  defp send_request_email(request, redirect_url) do
    email =
      request
      |> ForgetPasswordEmail.create(redirect_url)
      |> Mailer.deliver_now()

    {:ok, email}
  end

  @doc """
  Completes the reset password request flow for a user.

  This function is used when the eWallet is setup as a standalone solution,
  allowing users to reset their password without going through the integration
  with the provider's server.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{
        "email" => email,
        "token" => token,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    case ResetPasswordGate.update(email, token, password, password_confirmation) do
      {:ok, _user} ->
        render(conn, :empty, %{success: true})

      # Prevents attackers from gaining knowledge about a user's email.
      {:error, :user_email_not_found} ->
        handle_error(conn, :invalid_reset_token)

      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  def update(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "`email`, `token`, `password` and `password_confirmation` are required"
    )
  end
end
