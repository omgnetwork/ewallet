defmodule AdminAPI.V1.SocketProviderAuth do
  @moduledoc """
  This module takes care of authenticating a provider for websocket connections.
  """
  alias AdminAPI.V1.ProviderAuth

  def authenticate(auth) do
    auth
    |> parse_header()
    |> authenticate_access()
  end

  defp parse_header(auth) do
    case ProviderAuth.parse_header(auth[:auth_header]) do
      {:ok, access, secret} ->
        auth
        |> Map.put(:auth_access_key, access)
        |> Map.put(:auth_secret_key, secret)

      {:error, :invalid_auth_scheme} ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)
    end
  end

  # Skip auth if it already failed since header parsing
  defp authenticate_access(%{authenticated: false} = auth), do: auth

  defp authenticate_access(auth) do
    access_key = auth[:auth_access_key]
    secret_key = auth[:auth_secret_key]

    case ProviderAuth.authenticate(access_key, secret_key) do
      {:ok, account} ->
        auth
        |> Map.put(:authenticated, :provider)
        |> Map.put(:account, account)

      {:error, :invalid_access_secret_key} ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_access_secret_key)
    end
  end
end
