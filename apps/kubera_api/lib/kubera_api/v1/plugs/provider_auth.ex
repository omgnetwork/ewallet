defmodule KuberaAPI.V1.Plug.ProviderAuth do
  @moduledoc """
  This plug checks if valid access and secret keys were provided.

  If keys are valid, the plug assigns the account to the connection
  so that further connection consumers know which account
  this request belongs to.
  """
  import Plug.Conn
  import KuberaAPI.V1.ErrorHandler
  alias KuberaDB.Key

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> parse_header()
    |> authenticate()
  end

  defp parse_header(conn) do
    header =
      conn
      |> get_req_header("authorization")
      |> List.first()

    keys =
      case String.split(header, " ", parts: 2) do
        [type, auth] when type in ["Basic", "OMGServer"] ->
          auth
          |> Base.decode64!()
          |> String.split(":", parts: 2)
        _ ->
          :error
      end

    case keys do
      [access_key, secret_key] ->
        conn
        |> put_private(:auth_access_key, access_key)
        |> put_private(:auth_secret_key, secret_key)
      _ ->
        conn
    end
  end

  defp authenticate(conn) do
    access_key = conn.private[:auth_access_key]
    secret_key = conn.private[:auth_secret_key]

    case Key.authenticate(access_key, secret_key) do
      false ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_access_secret_key)
      account ->
        conn
        |> assign(:authenticated, :provider)
        |> assign(:account, account)
    end
  end
end
