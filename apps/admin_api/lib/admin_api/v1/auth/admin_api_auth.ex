defmodule AdminAPI.V1.AdminAPIAuth do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  alias AdminAPI.V1.{AdminUserAuth, ProviderAuth}

  def authenticate(params) do
    # auth is an agnostic replacement for the conn being passed around
    # in plugs. This is a map created here and filled with authentication
    # details that will be used either in socket auth directly or through
    # a plug to assign data to conn.
    auth = %{}

    (params["headers"] || params[:headers])
    |> Enum.into(%{})
    |> extract_auth_scheme(auth)
    |> do_authenticate()
  end

  defp extract_auth_scheme(params, auth) do
    with header when not is_nil(header) <- get_authorization_header(params),
         [scheme, _content] <- String.split(header, " ", parts: 2) do
      auth
      |> Map.put(:auth_scheme_name, scheme)
      |> Map.put(:auth_header, header)
    else
      _error ->
        auth
    end
  end

  defp get_authorization_header(headers) do
    headers["authorization"]
  end

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

  defp do_authenticate(auth) do
    auth
    |> Map.put(:authenticated, false)
    |> Map.put(:auth_error, :invalid_auth_scheme)
  end
end
