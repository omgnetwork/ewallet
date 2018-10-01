defmodule EWallet.Web.Inviter do
  @moduledoc """
  This module handles user invite and confirmation of their emails.
  """
  alias EWallet.Mailer
  alias EWalletDB.{Account, AccountUser, Helpers.Crypto, Invite, Membership, Role, User}

  @doc """
  Creates the end user if it does not exist, then sends the invite email out.
  """
  @spec invite_user(String.t(), String.t(), String.t(), String.t(), fun()) ::
          {:ok, %Invite{}} | {:error, atom()} | {:error, atom(), String.t()}
  def invite_user(email, password, verification_url, success_url, create_email_func) do
    with {:ok, user} <- get_or_insert_user(email, password, :self),
         {:ok, invite} <- Invite.generate(user, preload: :user, success_url: success_url),
         {:ok, account} <- Account.fetch_master_account(),
         {:ok, _account_user} <- AccountUser.link(account.uuid, user.uuid) do
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
         {:ok, invite} <- Invite.generate(user, preload: :user),
         {:ok, _membership} <- Membership.assign(invite.user, account, role) do
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
