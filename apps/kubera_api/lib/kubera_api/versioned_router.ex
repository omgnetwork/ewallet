defmodule KuberaAPI.VersionedRouter do
  @moduledoc """
  A router plug that attempts to figure out the requested API version,
  routes to the router for the specified version, and handles invalid
  version.
  """
  import Plug.Conn
  alias KuberaAPI.V1.{ErrorView, Router}
  alias Phoenix.Controller

  def init(opts), do: opts

  @doc """
  Attempts to retrieve requested version,
  and routes to respective router for that version.
  """
  def call(conn, opts) do
    case get_accept_version(conn) do
      {:ok, [:v1]} ->
        Router.call(conn, Router.init(opts))
      _ ->
        handle_invalid_version(conn)
    end
  end

  defp get_accept_version(conn) do
    [accept] = get_req_header(conn, "accept")

    mime_types = Application.get_env(:mime, :types)
    Map.fetch(mime_types, accept)
  end

  defp handle_invalid_version(conn) do
    accept_info =
      case get_req_header(conn, "accept") do
        [accept] ->
          accept_info = "Given \"" <> accept <> "\"."
        _ ->
          accept_info = "Accept header not found."
      end

    conn
    |> put_status(:bad_request)
    |> Controller.render(ErrorView, "error.json", %{
        code: "invalid_request_version",
        message: "Invalid request version. " <> accept_info
      })
    |> halt()
  end
end
