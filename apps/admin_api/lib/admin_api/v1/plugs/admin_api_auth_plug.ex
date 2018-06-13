defmodule AdminAPI.V1.AdminAPIAuthPlug do
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
    UserAuthPlug.call(conn, UserAuthPlug.init())
  end

  defp authenticate("Basic", conn), do: authenticate("OMGServer", conn)

  defp authenticate("OMGServer", conn) do
    ProviderAuth.call(conn, nil)
  end

  defp authenticate(_, conn) do
    conn
    |> assign(:authenticated, false)
    |> handle_error(:invalid_auth_scheme)
  end
end
