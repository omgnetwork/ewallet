defmodule AdminAPI.V1.UpdateEmailController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.UpdateEmailEmail
  alias AdminAPI.V1.UserView
  alias Bamboo.Email
  alias Ecto.Changeset
  alias EWallet.Mailer
  alias EWallet.Web.UrlValidator
  alias EWalletDB.{UpdateEmailRequest, User}

  @doc """
  Creates the user's change email request.
  """
  @spec self_update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def self_update(conn, %{"email" => email, "redirect_url" => redirect_url})
      when not is_nil(email) and not is_nil(redirect_url) do
    with {:ok, redirect_url} <- validate_redirect_url(redirect_url),
         {:ok, user} <- permit(:update_email, conn.assigns),
         {:ok, email} <- validate_email_unused(email),
         {_, _} <- UpdateEmailRequest.disable_all_for(user),
         %UpdateEmailRequest{} = request <- UpdateEmailRequest.generate(user, email),
         %Email{} = email_object <- UpdateEmailEmail.create(request, redirect_url),
         %Email{} <- Mailer.deliver_now(email_object) do
      render(conn, UserView, :user, %{user: user})
    else
      {:error, code} ->
        handle_error(conn, code)

      {:error, code, meta} ->
        handle_error(conn, code, meta)
    end
  end

  def self_update(conn, _), do: handle_error(conn, :invalid_parameter)

  defp validate_email_unused(email) do
    case User.get_by(email: email) do
      %User{} ->
        {:error, :email_already_exists}

      nil ->
        {:ok, email}
    end
  end

  defp validate_redirect_url(url) do
    if UrlValidator.allowed_redirect_url?(url) do
      {:ok, url}
    else
      {:error, :prohibited_url, param_name: "redirect_url", url: url}
    end
  end

  @doc """
  Verifies the user's change email request
  """
  @spec self_verify(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def self_verify(
        conn,
        %{
          "email" => email,
          "token" => token
        }
      ) do
    with %UpdateEmailRequest{} = request <- get_request(email, token),
         {:ok, %User{} = user} <- update_email(request, email),
         _ <- UpdateEmailRequest.disable_all_for(user) do
      render(conn, UserView, :user, %{user: user})
    else
      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def self_verify(conn, _), do: handle_error(conn, :invalid_parameter)

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

  @spec permit(:update_email | :update_email_verification, map()) ::
          {:ok, %User{}} | :access_key_unauthorized
  defp permit(_action, %{admin_user: admin_user}) do
    {:ok, admin_user}
  end

  defp permit(_action, %{key: _key}) do
    {:error, :access_key_unauthorized}
  end
end
