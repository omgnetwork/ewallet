defmodule AdminAPI.V1.SocketAdminAPIAuth do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{ProviderAuthPlug, AdminUserAuthPlug}

  def authenticate(params) do
    auth = %{}

    params.http_headers
    |> Enum.into(%{})
    |> extract_auth_scheme(auth)
    |> authenticate()
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

  defp get_authorization_header(params) do
    headers = Enum.into(params.http_headers, %{})
    header = headers["authorization"]
  end

  defp authenticate(%{authenticated: false} = auth), do: auth

  defp authenticate(%{auth_scheme_name: "OMGAdmin"} = auth) do
    auth
    |> Map.put(:auth_scheme, :admin)
    |> SocketAdminUserAuth.authenticate()
  end

  defp authenticate(%{auth_scheme_name: "Basic"} = auth) do
    auth
    |> Map.put(:auth_scheme, :provider)
    |> SocketProviderAuth.authenticate()
  end

  defp authenticate("OMGProvider", auth) do
    auth
    |> Map.put(:auth_scheme, :provider)
    |> SocketProviderAuth.authenticate()
  end
end
