defmodule AdminAPI.V1.ResetPasswordController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.{Mailer, ForgetPasswordEmail}
  alias EWalletDB.{User, ForgetPasswordRequest}

  def reset(conn, %{"email" => email, "redirect_url" => redirect_url}) do
    case User.get_by_email(email) do
      nil -> handle_error(conn, :user_email_not_found)
      user ->
        user
        |> ForgetPasswordRequest.delete_all()
        |> ForgetPasswordRequest.generate()
        |> ForgetPasswordEmail.create(redirect_url)
        |> Mailer.deliver_now()

        render(conn, :empty, %{success: true})
    end
  end
  def reset(conn, _), do: handle_error(conn, :invalid_parameter)

  def update(conn, %{
    "email" => email,
    "token" => token,
    "password" => _,
    "password_confirmation" => _
  } = attrs) do
    with %User{} = user                     <- get_user(email),
         %ForgetPasswordRequest{} = request <- get_request(user, token),
         {:ok, %User{} = user}              <- update_password(request, attrs)
    do
      ForgetPasswordRequest.delete_all(user)
      render(conn, :empty, %{success: true})
    else
      error when is_atom(error) ->
        handle_error(conn, error)
      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end
  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  defp get_user(email) do
    User.get_by_email(email) || :user_email_not_found
  end

  defp get_request(user, token) do
    ForgetPasswordRequest.get(user, token) || :invalid_reset_token
  end

  defp update_password(request, %{
    "password" => password,
    "password_confirmation" => password_confirmation
  }) do
    User.update(request.user, %{
      password: password,
      password_confirmation: password_confirmation
    })
  end
end
