defmodule EWallet.SignupGate do
  @moduledoc """
  Handles signups of new users.
  """
  alias EWallet.EmailValidator
  alias EWallet.Web.Inviter
  alias EWalletAPI.V1.VerifyEmailController
  alias EWalletAPI.VerificationEmail
  alias EWalletDB.{Invite, Validator}

  @doc """
  Signs up new users.
  """
  @spec signup(map()) :: {:ok, %Invite{}} | {:error, atom() | Ecto.Changeset.t()}
  def signup(attrs) do
    with {:ok, email} <- EmailValidator.validate(attrs["email"]),
         {:ok, password} <- validate_passwords(attrs["password"], attrs["password_confirmation"]),
         {:ok, verification_url} <- validate_verification_url(attrs["verification_url"]),
         {:ok, success_url} <- validate_success_url(attrs["success_url"]) do
      Inviter.invite_user(email, password, verification_url, success_url, VerificationEmail)
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

  defp validate_verification_url(nil) do
    {:ok, VerifyEmailController.verify_url()}
  end

  defp validate_verification_url(url) do
    if valid_url?(url) do
      {:ok, url}
    else
      {:error, :invalid_parameter,
       "The given `verification_url` is not allowed to be used. Got: '#{url}'."}
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

  defp valid_url?(url) do
    base_url = Application.get_env(:ewallet, :base_url)
    String.starts_with?(url, base_url)
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
