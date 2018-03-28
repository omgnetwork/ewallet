defmodule EWallet.Web.V1.SocketClientAuth do
  @moduledoc """
  This module takes care of authenticating a client for websocket connections.
  """
  alias EWallet.Web.V1.ClientAuth

  def authenticate(params) do
    %{}
    |> parse_header(params)
    |> authenticate_client()
    |> authenticate_token()
  end

  defp parse_header(auth, params) do
    headers = Enum.into(params.http_headers, %{})
    header = headers["authorization"]

    case ClientAuth.parse_header(header) do
      {:ok, key, token} ->
        auth
        |> Map.put(:auth_api_key, key)
        |> Map.put(:auth_auth_token, token)
      {:error, :invalid_auth_scheme} ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)
    end
  end

  # Skip client auth if it already failed since header parsing
  defp authenticate_client(%{authenticated: :false} = auth), do: auth
  defp authenticate_client(auth) do
    api_key = auth[:auth_api_key]

    case ClientAuth.authenticate_client(api_key, :ewallet_api) do
      {:ok, account} ->
        Map.put(auth, :account, account)
      {:error, :invalid_api_key} ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_api_key)
    end
  end

  # Skip token auth if it already failed since API key validation
  defp authenticate_token(%{authenticated: :false} = auth), do: auth
  defp authenticate_token(auth) do
    auth_token = auth[:auth_auth_token]

    case ClientAuth.authenticate_token(auth_token, :ewallet_api) do
      {:ok, user} ->
        auth
        |> Map.put(:authenticated, :client)
        |> Map.put(:user, user)
      {:error, code} ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, code)
    end
  end
end
