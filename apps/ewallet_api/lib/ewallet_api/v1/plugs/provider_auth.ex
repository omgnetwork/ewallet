defmodule EWalletAPI.V1.Plug.ProviderAuth do
  @moduledoc """
  This plug checks if valid access and secret keys were provided.

  If keys are valid, the plug assigns the account to the connection
  so that further connection consumers know which account
  this request belongs to.
  """
  import Plug.Conn
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Web.V1.ProviderAuth

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

    case ProviderAuth.parse_header(header) do
      {:ok, access, secret} ->
        conn
        |> put_private(:auth_access_key, access)
        |> put_private(:auth_secret_key, secret)
      {:error, :invalid_auth_scheme} ->
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

    case ProviderAuth.authenticate(access_key, secret_key) do
       {:ok, account} ->
        conn
        |> assign(:authenticated, :provider)
        |> assign(:account, account)
      {:error, :invalid_access_secret_key} ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_access_secret_key)
    end
  end
end
