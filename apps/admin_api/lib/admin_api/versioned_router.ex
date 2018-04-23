defmodule AdminAPI.VersionedRouter do
  @moduledoc """
  A router plug that attempts to figure out the requested API version,
  routes to the router for the specified version, and handles invalid
  version.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler

  def init(opts), do: opts

  @doc """
  Attempts to retrieve requested version,
  and routes to respective router for that version.
  """
  def call(conn, opts) do
    [accept] = get_req_header(conn, "accept")

    # Call the respected version of the router if mapping found,
    # raise an error otherwise.
    case get_accept_version(accept) do
      {:ok, router_module} ->
        dispatch_to_router(conn, opts, router_module)

      _ ->
        handle_invalid_version(conn, accept)
    end
  end

  defp get_accept_version(accept) do
    api_version = Application.get_env(:admin_api, :api_versions)
    Map.fetch(api_version, accept)
  end

  defp dispatch_to_router(conn, opts, router_module) do
    opts = apply(router_module, :init, [opts])
    apply(router_module, :call, [conn, opts])
  end

  defp handle_invalid_version(conn, accept) do
    handle_error(conn, :invalid_version, %{"accept" => accept})
  end
end
