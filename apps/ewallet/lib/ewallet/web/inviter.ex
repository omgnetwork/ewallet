defmodule EWallet.Web.Inviter do
  @moduledoc """
  This module handles user invite and confirmation of their emails.
  """
  alias EWallet.{EmailValidator, Mailer}
  alias EWalletDB.{Account, AccountUser, Invite, Membership, Repo, Role, User, Validator}
  alias EWalletDB.Helpers.Crypto

  @doc """
  Creates the end user if it does not exist, then sends the invite email out.
  """
  @spec invite_user(String.t(), String.t(), String.t(), String.t(), Bamboo.Email.t()) ::
          {:ok, %Invite{}} | {:error, atom()}
  def invite_user(email, password, redirect_url, success_url, template) do
    with {:ok, email} <- EmailValidator.validate(email),
         {:ok, password} <- Validator.validate_password(password),
         {:ok, user} <- get_or_create_user(email, password),
         {:ok, success_url} <- validate_success_url(success_url),
         {:ok, invite} <- Invite.generate(user, preload: :user, success_url: success_url),
         account <- Account.get_master_account(),
         {:ok, _account_user} <- AccountUser.link(account.uuid, user.uuid) do
      send_email(invite, redirect_url, template)
    else
      {:error, error} ->
        {:error, error}

      {:error, error, description} ->
        {:error, error, description}
    end
  end

  defp validate_success_url(nil), do: {:ok, nil}

  defp validate_success_url(url) do
    if valid_url?(url) do
      {:ok, url}
    else
      {:error, :invalid_parameter,
       "The given `success_url` is not allowed to be used. Got: '#{url}'."}
    end
  end

  @doc """
  Creates the admin along with the membership if the admin does not exist,
  then sends the invite email out.
  """
  @spec invite_admin(String.t(), %Account{}, %Role{}, String.t(), Bamboo.Email.t()) ::
          {:ok, %Invite{}} | {:error, atom()}
  def invite_admin(email, account, role, redirect_url, template) do
    with {:ok, email} <- EmailValidator.validate(email),
         {:ok, user} <- get_or_create_user(email),
         {:ok, invite} <- Invite.generate(user, preload: :user),
         {:ok, _membership} <- Membership.assign(invite.user, account, role) do
      send_email(invite, redirect_url, template)
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp get_or_create_user(email, password \\ nil) do
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
          password: password || Crypto.generate_base64_key(32)
        })
    end
  end

  @doc """
  Sends the invite email.
  """
  @spec send_email(%Invite{}, String.t(), Bamboo.Email.t()) ::
          {:ok, %Invite{}} | {:error, :invalid_parameter, String.t()}
  def send_email(invite, redirect_url, template) do
    if valid_url?(redirect_url) do
      _ =
        invite
        |> Repo.preload(:user)
        |> template.create(redirect_url)
        |> Mailer.deliver_now()

      {:ok, invite}
    else
      {:error, :invalid_parameter,
       "The `redirect_url` is not allowed to be used. Got: '#{redirect_url}'."}
    end
  end

  defp valid_url?(url) do
    base_url = Application.get_env(:ewallet, :base_url)
    String.starts_with?(url, base_url)
  end
end
