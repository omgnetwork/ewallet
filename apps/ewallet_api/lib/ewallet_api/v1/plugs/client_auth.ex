defmodule EWalletAPI.V1.Plug.ClientAuth do
  @moduledoc """
  This plug checks if valid api key and token were provided.

  If api key and token are valid, the plug assigns the user
  associated with the token to the connection so that downstream
  consumers know which user this request belongs to.
  """
  import Plug.Conn
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Web.V1.ClientAuth

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


    case ClientAuth.parse_header(header) do
      {:ok, key, token} ->
        conn
        |> put_private(:auth_api_key, key)
        |> put_private(:auth_auth_token, token)
      {:error, :invalid_auth_scheme} ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_auth_scheme)
    end
  end

  # Skip client auth if it already failed since header parsing
  defp authenticate_client(%{assigns: %{authenticated: :false}} = conn), do: conn
  defp authenticate_client(conn) do
    api_key = conn.private[:auth_api_key]

    case ClientAuth.authenticate_client(api_key) do
      {:ok, account} ->
        conn
        |> assign(:account, account)
      {:error, :invalid_api_key} ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_api_key)
    end
  end

  # Skip token auth if it already failed since API key validation
  defp authenticate_token(%{assigns: %{authenticated: false}} = conn), do: conn
  defp authenticate_token(conn) do
    auth_token = conn.private[:auth_auth_token]

    case ClientAuth.authenticate_token(auth_token, :ewallet_api) do
      {:ok, user} ->
        conn
        |> assign(:authenticated, :client)
        |> assign(:user, user)
      {:error, code} ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(code)
    end
  end

  @doc """
  Expires the authentication token used in this connection.
  """
  def expire_token(conn) do
    token_string = conn.private[:auth_auth_token]
    ClientAuth.expire_token(token_string, :ewallet_api)

    conn
    |> assign(:authenticated, false)
    |> assign(:user, nil)
  end
end
