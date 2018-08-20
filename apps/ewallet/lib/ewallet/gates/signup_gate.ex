defmodule EWallet.SignupGate do
  @moduledoc """
  Handles signups of new users.
  """
  alias EWallet.EmailValidator
  alias EWallet.Web.Inviter
  alias EWalletAPI.VerificationEmail
  alias EWalletDB.{Invite, Validator}

  @doc """
  Signs up new users.
  """
  @spec signup(map()) :: {:ok, %Invite{}} | {:error, atom() | Ecto.Changeset.t()}
  def signup(attrs) do
    with {:ok, email} <- EmailValidator.validate(attrs["email"]),
         {:ok, password} <- validate_passwords(attrs["password"], attrs["password_confirmation"]),
         {:ok, redirect_url} <- validate_redirect_url(attrs["redirect_url"]) do
      Inviter.invite(email, password, redirect_url, VerificationEmail)
    else
      error -> error
    end
  end

  defp validate_passwords(password, password_confirmation) do
    case Validator.validate_password(password) do
      {:ok, password} ->
        if password == password_confirmation do
          {:ok, password}
        else
          {:error, :passwords_mismatch}
        end

      {:error, :too_short, [min_length: min_length]} ->
        {:error, :invalid_parameter,
         "Invalid parameter provided. `password` must be #{min_length} characters or more."}
    end
  end

  defp validate_redirect_url(url) when is_binary(url) and byte_size(url) > 0, do: {:ok, url}

  defp validate_redirect_url(_), do: {:error, :missing_redirect_url}

  @doc """
  Verifies a user's email address.
  """
  @spec verify_email(map()) :: {:ok, %EWalletDB.User{}} | {:error, atom() | Ecto.Changeset.t()}
  def verify_email(attrs) do
    with {:ok, email} <- EmailValidator.validate(attrs["email"]),
         {:ok, token} <- validate_token(attrs["token"]),
         {:ok, invite} <- Invite.fetch(email, token),
         {:ok, invite} <- Invite.accept(invite) do
      {:ok, invite.user}
    else
      error -> error
    end
  end

  defp validate_token(token) when is_binary(token) and byte_size(token) > 0, do: {:ok, token}

  defp validate_token(_), do: {:error, :missing_token}
end
