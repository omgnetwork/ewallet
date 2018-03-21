defmodule EWallet.Web.V1.SocketProviderAuth do
  alias EWallet.Web.V1.ProviderAuth

  def authenticate(params) do
    %{}
    |> parse_header(params)
    |> authenticate_access()
  end

  defp parse_header(auth, params) do
    headers = Enum.into(params.http_headers, %{})
    header = headers["authorization"]

    case ProviderAuth.parse_header(header) do
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
  defp authenticate_access(%{authenticated: :false} = auth), do: auth
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
