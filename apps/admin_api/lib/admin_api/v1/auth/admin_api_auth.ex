defmodule AdminAPI.V1.AdminAPIAuth do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  alias AdminAPI.V1.{AdminUserAuth, ProviderAuth}

  def authenticate(params) do
    auth = %{}

    params.http_headers
    |> Enum.into(%{})
    |> extract_auth_scheme(auth)
    |> do_authenticate()
  end

  defp extract_auth_scheme(params, auth) do
    case get_authorization_header(params) do
      nil ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)

      header ->
        [scheme, _content] = String.split(header, " ", parts: 2)

        auth
        |> Map.put(:auth_scheme_name, scheme)
        |> Map.put(:auth_header, header)
    end
  end

  defp get_authorization_header(headers) do
    headers["authorization"]
  end

  defp do_authenticate(%{authenticated: false} = auth), do: auth

  defp do_authenticate(%{auth_scheme_name: "OMGAdmin"} = auth) do
    auth
    |> Map.put(:auth_scheme, :admin)
    |> AdminUserAuth.authenticate()
  end

  defp do_authenticate(%{auth_scheme_name: "Basic"} = auth) do
    auth
    |> Map.put(:auth_scheme, :provider)
    |> ProviderAuth.authenticate()
  end

  defp do_authenticate(%{auth_scheme_name: "OMGProvider"} = auth) do
    auth
    |> Map.put(:auth_scheme, :provider)
    |> ProviderAuth.authenticate()
  end
end
