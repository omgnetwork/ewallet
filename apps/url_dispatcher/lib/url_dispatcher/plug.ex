defmodule UrlDispatcher.Plug do
  @moduledoc false
  import Plug.Conn, only: [resp: 3, halt: 1, put_status: 2]
  import Phoenix.Controller, only: [json: 2, redirect: 2]
  alias Plug.Static

  def init(options), do: options
  def call(conn, _opts), do: handle_request(conn.request_path, conn)

  defp handle_request("/", conn) do
    conn
    |> put_status(200)
    |> json(%{status: true})
    |> halt()
  end

  # Redirect all endpoints without trailing slash to one with trailing slash.
  defp handle_request("/api", conn), do: redirect(conn, to: "/api/")
  defp handle_request("/admin/api", conn), do: redirect(conn, to: "/admin/api/")
  defp handle_request("/public", conn), do: redirect(conn, to: "/public/")

  defp handle_request("/api/" <> _, conn), do: EWalletAPI.Endpoint.call(conn, [])
  defp handle_request("/admin/api/" <> _, conn), do: AdminAPI.Endpoint.call(conn, [])
  defp handle_request("/public/" <> _, conn) do
    opts = Static.init([
      at: "/public",
      from: Path.join(File.cwd!, "public"),
      only: ~w(uploads)
    ])

    case Static.call(conn, opts) do
      %{halted: true} = conn ->
        conn
      _ ->
        conn
        |> resp(404, "The url could not be resolved.")
        |> halt()
    end
  end

  defp handle_request(_, conn) do
    conn
    |> resp(404, "The url could not be resolved.")
    |> halt()
  end
end
