defmodule AdminAPI.V1.AdminAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminUserAuthenticator
  alias EWallet.AccountPolicy
  alias EWalletDB.{AuthToken, Account}

  @doc """
  Authenticates a user with the given email and password.
  Returns with a newly generated authentication token if auth is successful.
  """
  def login(conn, %{
        "email" => email,
        "password" => password
      })
      when is_binary(email) and is_binary(password) do
    conn
    |> AdminUserAuthenticator.authenticate(email, password)
    |> respond_with_token()
  end

  def login(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  def switch_account(conn, %{"account_id" => account_id}) do
    with {:ok, _current_user} <- permit(:get, conn.assigns),
         %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit_account(:get, conn.assigns, account.id),
         token <- conn.private.auth_auth_token,
         %AuthToken{} = token <-
           AuthToken.get_by_token(token, :admin_api) || :auth_token_not_found,
         {:ok, token} <- AuthToken.switch_account(token, account) do
      render_token(conn, token)
    else
      error when is_atom(error) ->
        render_error(conn, {:error, error})

      error ->
        render_error(conn, error)
    end
  end

  def switch_account(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp respond_with_token(%{assigns: %{authenticated: true}} = conn) do
    {:ok, auth_token} = AuthToken.generate(conn.assigns.admin_user, :admin_api)
    render_token(conn, auth_token)
  end

  defp respond_with_token(conn) do
    render_error(conn, {:error, :invalid_login_credentials})
  end

  defp render_token(conn, auth_token) do
    render(conn, :auth_token, %{auth_token: auth_token})
  end

  defp render_error(conn, {:error, code}) do
    handle_error(conn, code)
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
      error ->
        render_error(conn, {:error, error})
    end
  end

  @spec permit(:all | :create | :get | :update, any()) ::
          {:ok, User.t()} | {:error, any()} | no_return()
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
