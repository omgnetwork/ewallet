defmodule AdminAPI.V1.AdminUserAuthenticator do
  @moduledoc """
  Perform authentication with the given email and password.
  It returns the associated user if authenticated, `false` otherwise.
  """
  import Plug.Conn
  alias EWalletConfig.Helpers.Crypto
  alias EWalletDB.{AuthToken, User}

  def authenticate(conn, email, password) when is_binary(email) do
    with %User{} = user <- User.get_by_email(email) || :user_email_not_found,
         true <- User.enabled?(user) || :user_disabled,
         true <- User.admin?(user) || :user_not_admin do
      authenticate(conn, user, password)
    else
      _ ->
        Crypto.fake_verify()
        handle_fail_auth(conn, :invalid_login_credentials)
    end
  end

  def authenticate(conn, %{password_hash: password_hash} = user, password)
      when is_binary(password) and is_binary(password_hash) do
    case Crypto.verify_password(password, password_hash) do
      true ->
        conn
        |> assign(:authenticated, true)
        |> assign(:auth_scheme, :admin)
        |> assign(:admin_user, user)

      _ ->
        handle_fail_auth(conn, :invalid_login_credentials)
    end
  end

  def authenticate(conn, _user, _password) do
    Crypto.fake_verify()
    handle_fail_auth(conn, :invalid_login_credentials)
  end

  @doc """
  Expires the authentication token used in this connection.
  """
  def expire_token(conn) do
    token_string = conn.private[:auth_auth_token]
    AuthToken.expire(token_string, :admin_api)
    handle_fail_auth(conn, :auth_token_expired)
  end

  defp handle_fail_auth(conn, error) do
    conn
    |> assign(:authenticated, false)
    |> assign(:auth_error, error)
  end
end
