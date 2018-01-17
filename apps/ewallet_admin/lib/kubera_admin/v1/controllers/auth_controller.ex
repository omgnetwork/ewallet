defmodule EWalletAdmin.V1.AuthController do
  use EWalletAdmin, :controller
  import EWalletAdmin.V1.ErrorHandler
  alias EWalletAdmin.V1.UserAuthPlug
  alias EWalletDB.AuthToken

  @doc """
  Authenticates a user with the given email and password.
  Returns with a newly generated authentication token if auth is successful.
  """
  def login(conn, %{
    "email" => email,
    "password" => password
  }) when is_binary(email) and is_binary(password) do
    conn
    |> UserAuthPlug.authenticate(email, password)
    |> respond_with_token()
  end
  def login(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp respond_with_token(%{assigns: %{authenticated: :user}} = conn) do
    auth_token = AuthToken.generate(conn.assigns.user, :ewallet_admin)
    render(conn, :auth_token, %{auth_token: auth_token, user: conn.assigns.user})
  end
  defp respond_with_token(conn) do
    handle_error(conn, :invalid_login_credentials)
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
