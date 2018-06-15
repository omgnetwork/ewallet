defmodule AdminAPI.V1.AdminUserAuthPlug do
  @moduledoc """
  This plug checks if a pair of valid user ID and authentication token were provided.

  On success, the plug assigns the following to `conn.assigns`:

    - `authenticated`: Set to `:user` to indicate that the request has been authenticated
                       at the user level.
    - `user`: The user that is associated with the authentication token.

  On failure, the plug assigns the following to `conn.assigns`:

    - `authenticated`: Set to `false`.
    - `user`: Not assigned.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminUserAuth
  alias EWalletDB.{AuthToken, User}
  alias EWalletDB.Helpers.Crypto
  alias Plug.Conn

  @doc """
  API used by Plug to start user authentication.
  """
  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @doc """
  API used by Plug to authenticate the user.
  """
  @spec call(Conn.t(), keyword()) :: Conn.t()
  def call(conn, _opts) do
    conn
    |> parse_header()
    |> authenticate()
  end

  def parse_header() do
    header =
      conn
      |> get_req_header("authorization")
      |> List.first()

    case AdminAuth.parse_header(header) do
      {:ok, user_id, auth_token} ->
        conn
        |> put_private(:auth_user_id, user_id)
        |> put_private(:auth_auth_token, auth_token)

      {:error, :invalid_auth_scheme} ->
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
        |> assign(:user, user)

      false ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:auth_token_not_found)

      :token_expired ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:auth_token_expired)
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
