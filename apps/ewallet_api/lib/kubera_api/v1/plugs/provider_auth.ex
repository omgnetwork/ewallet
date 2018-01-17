defmodule EWalletAPI.V1.Plug.ProviderAuth do
  @moduledoc """
  This plug checks if valid access and secret keys were provided.

  If keys are valid, the plug assigns the account to the connection
  so that further connection consumers know which account
  this request belongs to.
  """
  import Plug.Conn
  import EWalletAPI.V1.ErrorHandler
  alias EWalletDB.Key

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

    with header when not is_nil(header) <- header,
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGServer"],
         {:ok, decoded} <- Base.decode64(content),
         [access, secret] <- String.split(decoded, ":", parts: 2) do
      conn
      |> put_private(:auth_access_key, access)
      |> put_private(:auth_secret_key, secret)
    else
      _ ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_auth_scheme)
    end
  end

  # Skip auth if it already failed since header parsing
  defp authenticate(%{assigns: %{authenticated: false}} = conn), do: conn
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
