defmodule AdminAPI.V1.AdminUserAuthenticator do
  @doc """
  Perform authentication with the given email and password.
  It returns the associated user if authenticated, `false` otherwise.
  """
  import Plug.Conn
  alias EWalletDB.{User, AuthToken}
  alias EWalletDB.Helpers.Crypto

  def authenticate(conn, email, password) when is_binary(email) do
    user = User.get_by_email(email)
    authenticate(conn, user, password)
  end

  def authenticate(conn, %{password_hash: password_hash} = user, password)
      when is_binary(password) and is_binary(password_hash) do
    case Crypto.verify_password(password, password_hash) do
      true ->
        conn
        |> assign(:authenticated, :user)
        |> assign(:user, user)

      _ ->
        assign(conn, :authenticated, false)
    end
  end

  def authenticate(conn, _user, _password) do
    Crypto.fake_verify()
    assign(conn, :authenticated, false)
  end

  @doc """
  Expires the authentication token used in this connection.
  """
  def expire_token(conn) do
    token_string = conn.private[:auth_auth_token]
    AuthToken.expire(token_string, :admin_api)

    conn
    |> assign(:authenticated, false)
    |> assign(:user, nil)
  end
end
