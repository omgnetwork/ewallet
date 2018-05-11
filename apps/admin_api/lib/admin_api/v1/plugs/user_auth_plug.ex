defmodule AdminAPI.V1.UserAuthPlug do
  @moduledoc """
  This plug checks if a pair of valid user ID and authentication token were provided.

  On success, the plug assigns the following to `conn.assigns`:

    - `authenticated`: Set to `:user` to indicate that the request has been authenticated
                       at the user level.
    - `api_key_id`: The API key used to authenticate the request
                    (set if enable_client_auth == true, otherwise not assigned).
    - `user`: The user that is associated with the authentication token.

  On failure, the plug assigns the following to `conn.assigns`:

    - `authenticated`: Set to `false`.
    - `api_key_id`: Not assigned.
    - `user`: Not assigned.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias EWalletDB.Helpers.Crypto
  alias EWalletDB.{AuthToken, User}
  alias AdminAPI.V1.ClientAuthPlug

  def init(opts) do
    Keyword.put_new(
      opts,
      :enable_client_auth,
      Application.get_env(:admin_api, :enable_client_auth)
    )
  end

  def call(conn, opts) do
    case Keyword.get(opts, :enable_client_auth) do
      true ->
        conn
        |> parse_header()
        |> ClientAuthPlug.authenticate()
        |> authenticate_token()

      _ ->
        conn
        |> parse_header()
        |> authenticate_token()
    end
  end

  defp get_header(conn) do
    conn
    |> get_req_header("authorization")
    |> List.first()
  end

  defp parse_header(conn) do
    with header when not is_nil(header) <- get_header(conn),
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["OMGAdmin"],
         {:ok, decoded} <- Base.decode64(content),
         keys <- String.split(decoded, ":", parts: 4) do
      case keys do
        [key_id, key, user_id, token] ->
          conn
          |> put_private(:auth_api_key_id, key_id)
          |> put_private(:auth_api_key, key)
          |> put_private(:auth_user_id, user_id)
          |> put_private(:auth_auth_token, token)

        [user_id, token] ->
          conn
          |> put_private(:auth_user_id, user_id)
          |> put_private(:auth_auth_token, token)
      end
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
    user_id = conn.private[:auth_user_id]
    auth_token = conn.private[:auth_auth_token]

    case AuthToken.authenticate(user_id, auth_token, :admin_api) do
      %User{} = user ->
        conn
        |> assign(:authenticated, :user)
        |> assign(:api_key_id, conn.private[:auth_api_key_id])
        |> assign(:user, user)

      false ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:access_token_not_found)

      :token_expired ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:access_token_expired)
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
