defmodule AdminAPI.V1.AdminAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminUserAuthenticator
  alias EWallet.AccountPolicy
  alias EWalletDB.{Account, AuthToken, User}

  @doc """
  Authenticates a user with the given email and password.
  Returns with a newly generated authentication token if auth is successful.
  """
  def login(conn, attrs) do
    with email when is_binary(email) <- attrs["email"] || :missing_email,
         password when is_binary(password) <- attrs["password"] || :missing_password,
         conn <- AdminUserAuthenticator.authenticate(conn, attrs["email"], attrs["password"]),
         true <- conn.assigns.authenticated || :invalid_login_credentials,
         true <- User.get_status(conn.assigns.admin_user) == :active || :invite_pending,
         {:ok, auth_token} = AuthToken.generate(conn.assigns.admin_user, :admin_api) do
      render_token(conn, auth_token)
    else
      :missing_email ->
        handle_error(conn, :invalid_parameter, "Invalid parameter provided. `email` is required")

      :missing_password ->
        handle_error(
          conn,
          :invalid_parameter,
          "Invalid parameter provided. `password` is required"
        )

      error_code ->
        handle_error(conn, error_code)
    end
  end

  def switch_account(conn, %{"account_id" => account_id}) do
    with {:ok, _current_user} <- permit(:get, conn.assigns),
         %Account{} = account <- Account.get(account_id) || :unauthorized,
         :ok <- permit_account(:get, conn.assigns, account.id),
         token <- conn.private.auth_auth_token,
         %AuthToken{} = token <-
           AuthToken.get_by_token(token, :admin_api) || :auth_token_not_found,
         {:ok, token} <- AuthToken.switch_account(token, account) do
      render_token(conn, token)
    else
      {:error, error} ->
        handle_error(conn, error)

      error ->
        handle_error(conn, error)
    end
  end

  def switch_account(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp render_token(conn, auth_token) do
    render(conn, :auth_token, %{auth_token: auth_token})
  end

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, _attrs) do
    with {:ok, _current_user} <- permit(:update, conn.assigns) do
      conn
      |> AdminUserAuthenticator.expire_token()
      |> render(:empty_response, %{})
    else
      error_code ->
        handle_error(conn, error_code)
    end
  end

  @spec permit(:get | :update, map()) :: {:ok, %EWalletDB.User{}} | atom() | no_return()
  defp permit(_action, %{admin_user: admin_user}) do
    {:ok, admin_user}
  end

  defp permit(_action, %{key: _key}) do
    :access_key_unauthorized
  end

  defp permit_account(action, params, account_id) do
    Bodyguard.permit(AccountPolicy, action, params, account_id)
  end
end
