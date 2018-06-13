defmodule AdminAPI.V1.AdminAPIAuthPlug do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{ProviderAuth, UserAuthPlug}

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> extract_auth_scheme()
    |> authenticate(conn)
  end

  defp extract_auth_scheme(conn) do
    header =
      conn
      |> get_req_header("authorization")
      |> List.first()

    [scheme, _content] = String.split(header, " ", parts: 2)
    scheme
  end

  defp authenticate("OMGAdmin", conn) do
    conn
    |> assign(:auth_scheme, :admin)
    |> UserAuthPlug.call(UserAuthPlug.init())
  end

  defp authenticate("Basic", conn), do: authenticate("OMGProvider", conn)

  defp authenticate("OMGProvider", conn) do
    conn
    |> assign(:auth_scheme, :provider)
    |> ProviderAuth.call(nil)
  end

  defp authenticate(_, conn) do
    conn
    |> assign(:authenticated, false)
    |> handle_error(:invalid_auth_scheme)
  end
end
