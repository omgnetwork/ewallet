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

defmodule EWallet.ResetPasswordGate do
  @moduledoc """
  Handles a user's password reset.
  """
  alias EWalletDB.{ForgetPasswordRequest, User}

  @doc """
  Creates a reset password reset.
  """
  @spec request(map()) ::
          {:ok, %ForgetPasswordRequest{}}
          | {:error, :user_email_not_found}
          | {:error, Ecto.Changeset.t()}
  def request(email) do
    with {:ok, user} <- get_user_by_email(email),
         {:ok, request} <- ForgetPasswordRequest.generate(user) do
      {:ok, request}
    else
      error -> error
    end
  end

  @doc """
  Verifies a reset password request and updates the password.
  """
  @spec update(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, %User{}}
          | {:error, :user_email_not_found}
          | {:error, :invalid_reset_token}
          | {:error, Ecto.Changeset.t()}
  def update(email, token, password, password_confirmation) do
    with {:ok, user} <- get_user_by_email(email),
         {:ok, request} <- get_request(user, token),
         {:ok, user} <- update_password(request, password, password_confirmation),
         {:ok, _} <- ForgetPasswordRequest.expire_as_used(request) do
      {:ok, user}
    else
      error -> error
    end
  end

  # Private functions

  defp get_user_by_email(nil), do: {:error, :user_email_not_found}

  defp get_user_by_email(email) do
    case User.get_by_email(email) do
      nil -> {:error, :user_email_not_found}
      user -> {:ok, user}
    end
  end

  defp get_request(user, token) when is_nil(user) when is_nil(token) do
    {:error, :invalid_reset_token}
  end

  defp get_request(user, token) do
    case ForgetPasswordRequest.get(user, token) do
      nil ->
        {:error, :invalid_reset_token}

      request ->
        case NaiveDateTime.compare(NaiveDateTime.utc_now(), request.expires_at) do
          :gt ->
            {:error, :invalid_reset_token}

          _ ->
            {:ok, request}
        end
    end
  end

  defp update_password(request, password, password_confirmation) do
    User.update_password(
      request.user,
      %{
        password: password,
        password_confirmation: password_confirmation,
        originator: request
      },
      ignore_current: true
    )
  end
end
