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

  def update(conn, %{
    "token" => token,
    "password" => password,
    "password_confirmation" => password_confirmation
  }) do
    case ForgetPasswordRequest.get(token) do
      nil -> handle_error(conn, :invalid_reset_token)
      request ->
        request.user
        |> User.update(%{
          password: password,
          password_confirmation: password_confirmation
        })
        |> respond_single(conn)
    end
  end

  defp respond_single({:ok, %User{} = user}, conn) do
    ForgetPasswordRequest.delete_all(user)
    render(conn, :empty, %{success: true})
  end
  defp respond_single({:error, changeset}, conn) do
     handle_error(conn, :invalid_parameter, changeset)
   end
end
