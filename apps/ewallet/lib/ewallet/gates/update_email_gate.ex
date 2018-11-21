defmodule EWallet.UpdateEmailGate do
  @moduledoc """
  Handles a user's email update.
  """
  alias EWalletDB.{UpdateEmailRequest, User}

  def update(user, email_address) do
    with {:ok, email_address} <- validate_email_unused(email_address),
         {_, _} <- UpdateEmailRequest.disable_all_for(user),
         %UpdateEmailRequest{} = request <- UpdateEmailRequest.generate(user, email_address) do
      {:ok, request}
    else
      error -> error
    end
  end

  defp validate_email_unused(email) do
    case User.get_by(email: email) do
      %User{} ->
        {:error, :email_already_exists}

      nil ->
        {:ok, email}
    end
  end

  def verify(email, token) do
    with %UpdateEmailRequest{} = request <- get_request(email, token),
         {:ok, %User{} = user} <- update_email(request, email),
         _ <- UpdateEmailRequest.disable_all_for(user) do
      {:ok, user}
    else
      error -> error
    end
  end

  defp get_request(email, token) do
    UpdateEmailRequest.get(email, token) || {:error, :invalid_email_update_token}
  end

  defp update_email(request, email) do
    User.update_email(
      request.user,
      %{
        email: email,
        originator: request
      }
    )
  end
end
