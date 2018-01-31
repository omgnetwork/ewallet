defmodule UrlDispatcher.Plug do
  @moduledoc false
  import Plug.Conn, only: [resp: 3, halt: 1]

  def init(options) do
    options
  end

  def call(conn, _opts) do
    cond do
      conn.request_path =~ ~r{^/api} ->
        EWalletAPI.Endpoint.call(conn, [])
      conn.request_path =~ ~r{^/admin/api} ->
        AdminAPI.Endpoint.call(conn, [])
      true ->
        resp(conn, 404, "The url could not be resolved.") |> halt()
    end
  end
end
