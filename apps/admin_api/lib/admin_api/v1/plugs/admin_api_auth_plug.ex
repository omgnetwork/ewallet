defmodule AdminAPI.V1.AdminAPIAuthPlug do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{ProviderAuth, UserAuthPlug}

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> extract_auth_scheme()
    |> authenticate(conn, opts)
  end

  defp extract_auth_scheme(conn) do
    case get_authorization_header(conn) do
      nil ->
        authenticate(nil, conn, nil)

      header ->
        [scheme, _content] = String.split(header, " ", parts: 2)
        scheme
    end
  end

  defp get_authorization_header(conn) do
    conn
    |> get_req_header("authorization")
    |> List.first()
  end

  defp authenticate("OMGAdmin", conn, opts) do
    conn
    |> assign(:auth_scheme, :admin)
    |> UserAuthPlug.call(UserAuthPlug.init(opts))
  end

  defp authenticate("Basic", conn, opts), do: authenticate("OMGProvider", conn, opts)

  defp authenticate("OMGProvider", conn, opts) do
    conn
    |> assign(:auth_scheme, :provider)
    |> ProviderAuth.call(opts)
  end

  defp authenticate(_, conn, _opts) do
    conn
    |> assign(:authenticated, false)
    |> handle_error(:invalid_auth_scheme)
  end
end
