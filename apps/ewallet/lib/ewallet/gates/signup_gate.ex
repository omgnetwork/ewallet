defmodule EWallet.SignupGate do
  @moduledoc """
  Handles signups of new users.
  """
  alias EWallet.EmailValidator
  alias EWallet.Web.Inviter
  alias EWalletAPI.VerificationEmail

  @doc """
  Signs up new users.
  """
  @spec signup(map()) ::
          {:ok, %EWalletDB.Invite{}} | {:error, atom()} | {:error, Ecto.Changeset.t()}
  def signup(attrs) do
    with email when is_binary(email) <- attrs["email"] || :missing_email,
         password when is_binary(password) <- attrs["password"] || :missing_password,
         true <- password == attrs["password_confirmation"] || :passwords_mismatch,
         url when is_binary(url) <- attrs["redirect_url"] || :missing_redirect_url do
      Inviter.invite(email, url, VerificationEmail)
    else
      error_code -> {:error, error_code}
    end
  end

  @doc """
  Verifies a user's email address.
  """
  @spec verify_email(map()) ::
          {:ok, %EWalletDB.User{}} | {:error, atom()} | {:error, Ecto.Changeset.t()}
  def verify_email(attrs) do
    with email when is_binary(email) <- attrs["email"] || :missing_email,
         token when is_binary(token) <- attrs["token"] || :missing_token,
         password when is_binary(password) <- attrs["password"] || :missing_password,
         true <- password == attrs["password_confirmation"] || :passwords_mismatch,
         %Invite{} = invite <- Invite.get(email, token) || :email_token_not_found do
      case Invite.accept(invite, password) do
        {:ok, invite} -> {:ok, invite.user}
        {:error, changeset} -> {:error, changeset}
      end
    else
      error_code -> {:error, error_code}
    end
  end
end
