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

defmodule EWallet.UserGate do
  alias EWallet.{EmailValidator, InviteEmail}
  alias EWallet.Web.{UrlValidator, Inviter}
  alias EWalletDB.{User, Membership}

  # Get user or email specifically for `assign_user/2` above.
  #
  # Returns:
  # - `%User{}` if user_id is provided and found.
  # - `:unauthorized` if `user_id` is provided but not found.
  # - `%User{}` if email is provided and found.
  # - `string` email if email provided but not found.
  #
  # If both `user_id` and `email` are provided, only `user_id` is attempted.
  # Hence the pattern matching for `%{"user_id" => _}` comes first.
  def get_user_or_email(%{"user_id" => user_id}) do
    case User.get(user_id) do
      %User{} = user -> {:ok, user}
      _ -> {:error, :unauthorized}
    end
  end

  def get_user_or_email(%{"email" => nil}) do
    {:error, :invalid_email}
  end

  def get_user_or_email(%{"email" => email}) do
    case User.get_by_email(email) do
      %User{} = user -> {:ok, user}
      nil -> {:ok, email}
    end
  end

  def validate_redirect_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "redirect_url", url: url}
    end
  end

  def invite_global_user(%{"email" => email} = attrs, redirect_url) when is_binary(email) do
    case EmailValidator.validate(email) do
      {:ok, email} ->
        Inviter.invite_admin(
          attrs,
          redirect_url,
          &InviteEmail.create/2
        )

      error ->
        error
    end
  end

  def assign_or_invite(email, account, role, redirect_url, originator) when is_binary(email) do
    case EmailValidator.validate(email) do
      {:ok, email} ->
        Inviter.invite_admin(
          email,
          account,
          role,
          redirect_url,
          originator,
          &InviteEmail.create/2
        )

      error ->
        error
    end
  end

  def assign_or_invite(user, account, role, redirect_url, originator) do
    case User.get_status(user) do
      :pending_confirmation ->
        user
        |> User.get_invite()
        |> Inviter.send_email(redirect_url, &InviteEmail.create/2)

      :active ->
        Membership.assign(user, account, role, originator)
    end
  end
end
