defmodule UrlDispatcher.Plug do
  @moduledoc false
  import Plug.Conn, only: [resp: 3, halt: 1, put_status: 2]
  import Phoenix.Controller, only: [json: 2, redirect: 2]
  alias Plug.Static

  @public_folders ~w(uploads swagger)

  def init(options), do: options
  def call(conn, _opts), do: handle_request(conn.request_path, conn)

  defp handle_request("/", conn) do
    conn
    |> put_status(200)
    |> json(%{status: true})
  end

  defp handle_request("/api" <> _, conn), do: EWalletAPI.Endpoint.call(conn, [])
  defp handle_request("/admin/api" <> _, conn), do: AdminAPI.Endpoint.call(conn, [])
  defp handle_request("/admin" <> _, conn), do: AdminPanel.Endpoint.call(conn, [])

  defp handle_request("/public" <> _, conn) do
    opts =
      Static.init(
        at: "/public",
        from: Path.join(Application.get_env(:ewallet, :root), "public"),
        only: @public_folders
      )

    static_call(conn, opts)
  end

  defp handle_request("/docs", conn), do: redirect(conn, to: "/docs/index.html")

  defp handle_request("/docs" <> _, conn) do
    opts =
      Static.init(
        at: "/docs",
        from: Path.join(Application.get_env(:ewallet, :root), "public/docs")
      )

    static_call(conn, opts)
  end

  defp handle_request(_, conn) do
    conn
    |> resp(404, "The url could not be resolved.")
    |> halt()
  end

  defp static_call(conn, opts) do
    case Static.call(conn, opts) do
      %{halted: true} = conn ->
        conn

      _ ->
        conn
        |> resp(404, "The url could not be resolved.")
        |> halt()
    end
  end
end
