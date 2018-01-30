defmodule AdminAPI.V1.ResetPasswordController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.{Mailer, ForgetPasswordEmail}
  alias EWalletDB.{User, ForgetPasswordRequest}

  def reset(conn, %{"email" => email, "url" => url}) do
    case User.get_by_email(email) do
      nil -> handle_error(conn, :user_email_not_found)
      user ->
        user
        |> ForgetPasswordRequest.delete_all()
        |> ForgetPasswordRequest.generate()
        |> ForgetPasswordEmail.create(url)
        |> Mailer.deliver_now()

        render(conn, :empty, %{success: true})
    end
  end

  def update(conn, %{
    "token" => token,
    "password" => _,
    "password_confirmation" => _
  } = attrs) do
    case ForgetPasswordRequest.get(token) do
      nil -> handle_error(conn, :invalid_reset_token)
      request ->
        request.user
        |> User.update(attrs)
        |> respond_single(conn)
    end
  end

  # Respond with a single admin
  defp respond_single({:ok, %User{} = user}, conn) do
    ForgetPasswordRequest.delete_all(user)
    render(conn, :empty, %{success: true})
  end
  # Responds when the given params were invalid
  defp respond_single({:error, changeset}, conn) do
     handle_error(conn, :invalid_parameter, changeset)
   end
end
