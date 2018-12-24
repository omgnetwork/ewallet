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

defmodule EWallet.SignupGate do
  @moduledoc """
  Handles signups of new users.
  """
  alias EWallet.EmailValidator
  alias EWalletDB.Validator
  alias EWallet.Web.{Inviter, UrlValidator}
  alias EWalletDB.Invite

  @doc """
  Signs up new users.
  """
  @spec signup(map(), fun()) :: {:ok, %Invite{}} | {:error, atom() | Ecto.Changeset.t()}
  def signup(attrs, email_func) do
    with {:ok, email} <- EmailValidator.validate(attrs["email"]),
         {:ok, password} <- Validator.validate_password(attrs["password"]),
         true <- password == attrs["password_confirmation"] || {:error, :passwords_mismatch},
         {:ok, verification_url} <- validate_verification_url(attrs["verification_url"]),
         {:ok, success_url} <- validate_success_url(attrs["success_url"]) do
      Inviter.invite_user(
        email,
        password,
        verification_url,
        success_url,
        email_func
      )
    else
      error -> error
    end
  end

  defp validate_verification_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "verification_url", url: url}
    end
  end

  defp validate_success_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "success_url", url: url}
    end
  end

  @doc """
  Verifies a user's email address.
  """
  @spec verify_email(map()) :: {:ok, %EWalletDB.User{}} | {:error, atom() | Ecto.Changeset.t()}
  def verify_email(attrs) do
    with {:ok, email} <- EmailValidator.validate(attrs["email"]),
         {:ok, token} <- validate_token(attrs["token"]),
         {:ok, invite} <- Invite.fetch(email, token),
         {:ok, invite} <- Invite.accept(invite) do
      {:ok, invite}
    else
      error -> error
    end
  end

  defp validate_token(token) when is_binary(token) and byte_size(token) > 0, do: {:ok, token}

  defp validate_token(_), do: {:error, :missing_token}
end
