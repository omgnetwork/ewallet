defmodule EWallet.ResetPasswordGate do
  @moduledoc """
  Handles a user's password reset.
  """
  alias EWalletDB.{ForgetPasswordRequest, User}

  @doc """
  Creates a reset password reset.
  """
  @spec request(map()) :: %ForgetPasswordRequest{}
  def request(email) do
    with {:ok, user} <- get_user_by_email(email),
         {_, _} <- ForgetPasswordRequest.disable_all_for(user),
         {:ok, request} <- ForgetPasswordRequest.generate(user) do
      {:ok, request}
    else
      error -> error
    end
  end

  @doc """
  Verifies a reset password request and updates the password.
  """
  @spec update(String.t(), String.t(), String.t(), String.t()) :: {:ok, %User{}}
  def update(email, token, password, password_confirmation) do
    with {:ok, user} <- get_user_by_email(email),
         {:ok, request} <- get_request(user, token),
         {:ok, user} <- update_password(request, password, password_confirmation),
         {_, _} <- ForgetPasswordRequest.disable_all_for(user) do
      {:ok, user}
    else
      error -> error
    end
  end

  # Private functions

  defp get_user_by_email(nil), do: {:error, :user_email_not_found}
  defp get_user_by_email(email) do
    case User.get_by_email(email) do
      nil -> {:error, :user_email_not_found}
      user -> {:ok, user}
    end
  end

  defp get_request(user, token) when is_nil(user) when is_nil(token) do
    {:error, :invalid_reset_token}
  end
  defp get_request(user, token) do
    case ForgetPasswordRequest.get(user, token) do
      nil -> {:error, :invalid_reset_token}
      request -> {:ok, request}
    end
  end

  defp update_password(request, password, password_confirmation) do
    User.update_password(
      request.user,
      %{
        password: password,
        password_confirmation: password_confirmation,
        originator: request
      },
      ignore_current: true
    )
  end
end
