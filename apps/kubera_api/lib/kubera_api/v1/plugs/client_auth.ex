defmodule KuberaAPI.V1.Plug.ClientAuth do
  @moduledoc """
  This plug checks if valid api key and token were provided.

  If api key and token are valid, the plug assigns the user
  associated with the token to the connection so that downstream
  consumers know which user this request belongs to.
  """
  import Plug.Conn
  import KuberaAPI.V1.ErrorHandler
  alias KuberaDB.{APIKey, AuthToken}

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

    keys =
      case String.split(header, " ", parts: 2) do
        [type, auth] when type in ["Basic", "OMGClient"] ->
          auth
          |> Base.decode64!()
          |> String.split(":", parts: 2)
        _ ->
          :error
      end

    case keys do
      [api_key, auth_token] ->
        conn
        |> put_private(:auth_api_key, api_key)
        |> put_private(:auth_auth_token, auth_token)
      _ ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_auth_scheme)
    end
  end

  defp authenticate_client(%{assigns: %{authenticated: false}} = conn), do: conn
  defp authenticate_client(conn) do
    api_key = conn.private[:auth_api_key]

    case APIKey.authenticate(api_key) do
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

    case AuthToken.authenticate(auth_token) do
      false ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:access_token_not_found)
      user ->
        conn
        |> assign(:authenticated, :client)
        |> assign(:user, user)
    end
  end
end
