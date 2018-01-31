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
    error when is_atom(error) -> {:error, error}
  end

  defp validate_email(email) do
    if EmailValidator.valid?(email), do: email, else: throw :invalid_email
  end

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

  defp send(invite) do
    invite
    |> InviteEmail.create()
    |> Mailer.deliver_now()
  end
end
