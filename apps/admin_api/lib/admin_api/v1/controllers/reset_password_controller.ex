defmodule AdminAPI.V1.ResetPasswordController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.{Mailer, ForgetPasswordEmail}
  alias EWalletDB.{User, ForgetPasswordRequest}
  alias Bamboo.Email

  @spec reset(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def reset(conn, %{"email" => email, "redirect_url" => redirect_url})
      when not is_nil(email) and not is_nil(redirect_url) do
    with true <- valid_url?(redirect_url) || :invalid_redirect_url,
         %User{} = user <- User.get_by_email(email) || :user_email_not_found,
         {_, _} <- ForgetPasswordRequest.delete_all(user),
         %ForgetPasswordRequest{} = request <- ForgetPasswordRequest.generate(user),
         %Email{} = email_object <- ForgetPasswordEmail.create(request, redirect_url),
         %Email{} <- Mailer.deliver_now(email_object) do
      render(conn, :empty, %{success: true})
    else
      :invalid_redirect_url ->
        handle_error(
          conn,
          :invalid_parameter,
          "The `redirect_url` is not allowed to be used. Got: #{redirect_url}"
        )

      error_code ->
        handle_error(conn, error_code)
    end
  end

  def reset(conn, _), do: handle_error(conn, :invalid_parameter)

  defp valid_url?(url) do
    base_url = Application.get_env(:admin_api, :base_url)
    String.starts_with?(url, base_url)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(
        conn,
        %{
          "email" => email,
          "token" => token,
          "password" => _,
          "password_confirmation" => _
        } = attrs
      ) do
    with %User{} = user <- get_user(email),
         %ForgetPasswordRequest{} = request <- get_request(user, token),
         {:ok, %User{} = user} <- update_password(request, attrs) do
      _ = ForgetPasswordRequest.delete_all(user)
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
