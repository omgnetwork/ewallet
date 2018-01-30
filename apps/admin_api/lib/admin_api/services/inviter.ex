defmodule AdminAPI.Inviter do
  @moduledoc """
  This module handles user invite and confirmation of their emails.
  """
  alias AdminAPI.{InviteEmail, Mailer}
  alias EWallet.EmailValidator
  alias EWalletDB.{Invite, User}
  alias EWalletDB.Helpers.Crypto

  @doc """
  Creates the user if not exists, then sends the invite email out.
  """
  def invite(email, account, role) do
    {:ok, invite} =
      email
      |> validate_email()
      |> get_or_create_user()
      |> do_invite()

    send(invite)
    {:ok, invite}
  catch
    :user_already_active -> {:error, :user_already_active}
  end

  defp validate_email(email), do: EmailValidator.validate(email)

  defp get_or_create_user(email) do
    case User.get_by_email(email) do
      %User{} = user ->
        check_active(user)
      nil ->
        {:ok, user} = User.insert(%{
          email: email,
          password: Crypto.generate_key(32),
          metadata: %{}
        })
        user
    end
  end

  defp check_active(user) do
    case User.get_status(user) do
      :active -> throw :user_already_active
      _ -> user
    end
  end

  defp do_invite(user) do
    Invite.generate(user, preload: :user)
  end

  @doc """
  Sends or resends the user's invite.
  """
  def send(invite) do
    invite
    |> InviteEmail.create()
    |> Mailer.deliver_now()
  end
end
