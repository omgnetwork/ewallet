defmodule AdminAPI.V1.AuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.UserAuthPlug
  alias EWallet.AccountPolicy
  alias EWalletDB.{AuthToken, Account}

  defp permit(action, user_id, account_id) do
    Bodyguard.permit(AccountPolicy, action, user_id, account_id)
  end

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
    |> UserAuthPlug.authenticate(email, password)
    |> respond_with_token()
  end

  def login(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  def switch_account(conn, %{"account_id" => account_id}) do
    with token <- conn.private.auth_auth_token,
         %Account{} = account <- Account.get(account_id) || {:error, :account_not_found},
         :ok <- permit(:get, conn.assigns.user.id, account.id),
         %AuthToken{} = token <-
           AuthToken.get_by_token(token, :admin_api) || {:error, :auth_token_not_found},
         {:ok, token} <- AuthToken.switch_account(token, account) do
      render_token(conn, token)
    else
      error ->
        render_error(conn, error)
    end
  end

  def switch_account(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp respond_with_token(%{assigns: %{authenticated: :user}} = conn) do
    {:ok, auth_token} = AuthToken.generate(conn.assigns.user, :admin_api)
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
    conn
    |> UserAuthPlug.expire_token()
    |> render(:empty_response, %{})
  end
end
