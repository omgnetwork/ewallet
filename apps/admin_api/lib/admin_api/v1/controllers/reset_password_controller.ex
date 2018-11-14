defmodule AdminAPI.V1.ResetPasswordController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.ForgetPasswordEmail
  alias Bamboo.Email
  alias EWallet.Mailer
  alias EWallet.Web.UrlValidator
  alias EWalletDB.{ForgetPasswordRequest, User}

  @spec reset(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def reset(conn, %{"email" => email, "redirect_url" => redirect_url})
      when not is_nil(email) and not is_nil(redirect_url) do
    with {:ok, redirect_url} <- validate_redirect_url(redirect_url),
         %User{} = user <- User.get_by_email(email) || :user_email_not_found,
         {_, _} <- ForgetPasswordRequest.disable_all_for(user),
         %ForgetPasswordRequest{} = request <- ForgetPasswordRequest.generate(user),
         %Email{} = email_object <- ForgetPasswordEmail.create(request, redirect_url),
         %Email{} <- Mailer.deliver_now(email_object) do
      render(conn, :empty, %{success: true})
    else
      {:error, code, meta} ->
        handle_error(conn, code, meta)

      error_code ->
        handle_error(conn, error_code)
    end
  end

  def reset(conn, _), do: handle_error(conn, :invalid_parameter)

  defp validate_redirect_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "redirect_url", url: url}
    end
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
         attrs <- Map.put(attrs, "originator", request),
         {:ok, %User{} = user} <- update_password(request, attrs) do
      _ = ForgetPasswordRequest.disable_all_for(user)
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
