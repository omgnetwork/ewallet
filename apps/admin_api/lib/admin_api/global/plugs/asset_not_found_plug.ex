defmodule AdminAPI.AssetNotFoundPlug do
  @moduledoc """
  This plug checks if the current request is for an asset and returns 404 if
  it was not found.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    check_asset(conn, {conn.method, Enum.at(conn.path_info, 0)})
  end

  defp check_asset(conn, {"GET", "public"}) do
    conn
    |> send_resp(404, "")
    |> halt()
  end

  defp check_asset(conn, _), do: conn
end
