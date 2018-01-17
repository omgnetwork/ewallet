defmodule EWalletAPI.V1.Plug.ClientAuth do
  @moduledoc """
  This plug checks if valid api key and token were provided.

  If api key and token are valid, the plug assigns the user
  associated with the token to the connection so that downstream
  consumers know which user this request belongs to.
  """
  import Plug.Conn
  import EWalletAPI.V1.ErrorHandler
  alias EWalletDB.{APIKey, AuthToken}

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> parse_header()
    |> authenticate_client()
    |> authenticate_token()
  end

  defp parse_header(conn) do
    header =
      conn
      |> get_req_header("authorization")
      |> List.first()

    with header when not is_nil(header) <- header,
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGClient"],
         {:ok, decoded} <- Base.decode64(content),
         [key, token] <- String.split(decoded, ":", parts: 2) do
      conn
      |> put_private(:auth_api_key, key)
      |> put_private(:auth_auth_token, token)
    else
      _ ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_auth_scheme)
    end
  end

  # Skip client auth if it already failed since header parsing
  defp authenticate_client(%{assigns: %{authenticated: :false}} = conn), do: conn
  defp authenticate_client(conn) do
    api_key = conn.private[:auth_api_key]

    case APIKey.authenticate(api_key, :ewallet_api) do
      false ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_api_key)
      account ->
        conn
        |> assign(:account, account)
    end
  end

  # Skip token auth if it already failed since API key validation
  defp authenticate_token(%{assigns: %{authenticated: false}} = conn), do: conn
  defp authenticate_token(conn) do
    auth_token = conn.private[:auth_auth_token]

    case AuthToken.authenticate(auth_token, :ewallet_api) do
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
        |> assign(:authenticated, :client)
        |> assign(:user, user)
    end
  end

  @doc """
  Expires the authentication token used in this connection.
  """
  def expire_token(conn) do
    token_string = conn.private[:auth_auth_token]
    AuthToken.expire(token_string, :ewallet_api)

    conn
    |> assign(:authenticated, false)
    |> assign(:user, nil)
  end
end
