defmodule AdminAPI.V1.ClientAuthPlug do
  @moduledoc """
  This plug checks if valid `api_key_id` and `api_key` are provided.

  On success, the plug assigns the following `conn.assigns`:

    - `authenticated`: Set to `:client` to indicate that the request has been authenticated
                       at the client level.
    - `api_key_id`: The API key used to authenticate the request.
    - `auth_account`: The account that is associated with the API key.

  If client auth is disabled, the plug assigns the following `conn.assigns`:

    - `authenticated`: Set to `:client`.
    - `api_key_id`: Not assigned.
    - `auth_account`: Not assigned.

  On failure, the plug halts, then assigns the following `conn.assigns`:

    - `authenticated`: Set to `false`.
    - `api_key_id`: Not assigned.
    - `auth_account`: Not assigned.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias EWalletDB.{Account, APIKey}

  def init(opts), do: opts

  def call(conn, opts) do
    auth =
      Keyword.get(opts, :enable_client_auth, Application.get_env(:admin_api, :enable_client_auth))

    case auth do
      true ->
        conn
        |> parse_header()
        |> authenticate()

      _ ->
        assign(conn, :authenticated, :client)
    end
  end

  defp parse_header(conn) do
    header =
      conn
      |> get_req_header("authorization")
      |> List.first()

    with header when not is_nil(header) <- header,
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGAdmin"],
         {:ok, decoded} <- Base.decode64(content),
         [key_id, key] <- String.split(decoded, ":", parts: 2) do
      conn
      |> put_private(:auth_api_key_id, key_id)
      |> put_private(:auth_api_key, key)
    else
      _ ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_auth_scheme)
    end
  end

  @doc """
  Authenticates a client by using api_key_id and api_key in the connection (private values).
  """
  def authenticate(%{assigns: %{authenticated: false}} = conn), do: conn

  def authenticate(conn) do
    api_key_id = conn.private[:auth_api_key_id]
    api_key = conn.private[:auth_api_key]

    case APIKey.authenticate(api_key_id, api_key, :admin_api) do
      %Account{} = account ->
        conn
        |> assign(:authenticated, :client)
        |> assign(:api_key_id, api_key_id)
        |> assign(:auth_account, account)

      false ->
        conn
        |> assign(:authenticated, false)
        |> handle_error(:invalid_api_key)
    end
  end
end
