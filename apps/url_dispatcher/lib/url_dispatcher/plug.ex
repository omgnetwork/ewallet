defmodule UrlDispatcher.Plug do
  @moduledoc false
  import Plug.Conn, only: [resp: 3, halt: 1, send_resp: 3]
  alias Plug.Static

  def init(options) do
    options
  end

  def call(conn, _opts) do
    cond do
      conn.request_path =~ ~r{^/api} ->
        EWalletAPI.Endpoint.call(conn, [])
      conn.request_path =~ ~r{^/admin/api} ->
        AdminAPI.Endpoint.call(conn, [])
      conn.request_path =~ ~r{^/public} ->
        serve_static(conn)
      true ->
        conn
        |> resp(404, "The url could not be resolved.")
        |> halt()
    end
  end

  defp serve_static(conn) do
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
        |> send_resp(404, "")
        |> halt()
    end
  end
end
