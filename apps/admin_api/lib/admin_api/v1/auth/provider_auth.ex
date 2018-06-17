defmodule AdminAPI.V1.ProviderAuth do
  @moduledoc """
  This module takes care of authenticating a provider for websocket connections.
  """
  alias EWalletDB.Key

  def authenticate(auth) do
    auth
    |> parse_header()
    |> authenticate_access()
  end

  defp parse_header(auth) do
    with header when not is_nil(header) <- auth[:auth_header],
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGProvider"],
         {:ok, decoded} <- Base.decode64(content),
         [access, secret] <- String.split(decoded, ":", parts: 2) do
        auth
        |> Map.put(:auth_access_key, access)
        |> Map.put(:auth_secret_key, secret)
    else
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

    case Key.authenticate(access_key, secret_key) do
      {:ok, key} ->
        auth
        |> Map.put(:authenticated, true)
        |> Map.put(:key, key)

      :error ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_access_secret_key)
    end
  end
end
