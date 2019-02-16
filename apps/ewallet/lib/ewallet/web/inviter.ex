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

defmodule EWallet.Web.Inviter do
  @moduledoc """
  This module handles user invite and confirmation of their emails.
  """
  alias EWallet.Mailer
  alias Utils.Helpers.Crypto
  alias EWalletDB.{Account, AccountUser, Invite, Membership, Role, User}

  @doc """
  Creates the end user if it does not exist, then sends the invite email out.
  """
  @spec invite_user(String.t(), String.t(), String.t(), String.t(), fun()) ::
          {:ok, %Invite{}} | {:error, atom()} | {:error, atom(), String.t()}
  def invite_user(email, password, verification_url, success_url, create_email_func) do
    with {:ok, user} <- get_or_insert_user(email, password, :self),
         {:ok, invite} <- Invite.generate(user, user, preload: :user, success_url: success_url),
         {:ok, account} <- Account.fetch_master_account(),
         {:ok, _account_user} <- AccountUser.link(account.uuid, user.uuid, user) do
      send_email(invite, verification_url, create_email_func)
    else
      {:error, error} ->
        {:error, error}

      {:error, error, description} ->
        {:error, error, description}
    end
  end

  @doc """
  Creates the admin along with the membership if the admin does not exist,
  then sends the invite email out.
  """
  @spec invite_admin(String.t(), %Account{}, %Role{}, String.t(), map() | atom(), fun()) ::
          {:ok, %Invite{}} | {:error, atom()}
  def invite_admin(email, account, role, redirect_url, originator, create_email_func) do
    with {:ok, user} <- get_or_insert_user(email, nil, originator),
         {:ok, invite} <- Invite.generate(user, originator, preload: :user),
         {:ok, _membership} <- Membership.assign(invite.user, account, role, originator) do
      send_email(invite, redirect_url, create_email_func)
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp get_or_insert_user(email, password, originator) do
    case User.get_by_email(email) do
      %User{} = user ->
        case User.get_status(user) do
          :active ->
            {:error, :user_already_active}

          _ ->
            {:ok, user}
        end

      nil ->
        User.insert(%{
          email: email,
          password: password || Crypto.generate_base64_key(32),
          originator: originator
        })
    end
  end

  @doc """
  Sends the invite email.
  """
  @spec send_email(%Invite{}, String.t(), (%Invite{}, String.t() -> Bamboo.Email.t())) ::
          {:ok, %Invite{}}
  def send_email(invite, redirect_url, create_email_func) do
    _ =
      invite
      |> create_email_func.(redirect_url)
      |> Mailer.deliver_now()

    {:ok, invite}
  end
end
