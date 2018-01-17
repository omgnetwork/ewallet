defmodule AdminAPI.V1.UserAuthPlug do
  @moduledoc """
  This plug checks if valid api key and token were provided.

  If api key and token are valid, the plug assigns the user
  associated with the token to the connection so that downstream
  consumers know which user this request belongs to.

  The credentials in this plug may need to be stored on client's side,
  i.e. in the browser. Therefore high privilege credentials like
  EWalletDB.Key's `access_key` and `secret_key` should not be used.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias EWalletDB.Helpers.Crypto
  alias EWalletDB.{AuthToken, User}
  alias AdminAPI.V1.ClientAuthPlug

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> parse_header()
    |> ClientAuthPlug.authenticate()
    |> authenticate_token()
  end

  defp parse_header(conn) do
    header =
      conn
      |> get_req_header("authorization")
      |> List.first()

    with header when not is_nil(header) <- header,
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["OMGAdmin"],
         {:ok, decoded} <- Base.decode64(content),
         [key_id, key, user_id, token] <- String.split(decoded, ":", parts: 4) do
      conn
      |> put_private(:auth_api_key_id, key_id) # Used by ClientAuthPlug.authenticate/1
      |> put_private(:auth_api_key, key) # Used by ClientAuthPlug.authenticate/1
      |> put_private(:auth_user_id, user_id)
      |> put_private(:auth_auth_token, token)
    else
      _ ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_auth_scheme)
    end
  end

  # Skip token auth if it already failed since API key validation or header parsing
  defp authenticate_token(%{assigns: %{authenticated: false}} = conn), do: conn
  defp authenticate_token(conn) do
    user_id    = conn.private[:auth_user_id]
    auth_token = conn.private[:auth_auth_token]

    case AuthToken.authenticate(user_id, auth_token, :admin_api) do
      false ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:access_token_not_found)
      :token_expired ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:access_token_expired)
      user ->
        conn
        |> assign(:authenticated, :user)
        |> assign(:user, user)
    end
  end

  @doc """
  Perform authentication with the given email and password.
  It returns the associated user if authenticated, `false` otherwise.
  """
  def authenticate(conn, email, password) when is_binary(email) do
    user = User.get_by_email(email)
    authenticate(conn, user, password)
  end
  def authenticate(conn, %{password_hash: password_hash} = user, password)
    when is_binary(password) and is_binary(password_hash)
  do
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
    Crypto.fake_verify
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
