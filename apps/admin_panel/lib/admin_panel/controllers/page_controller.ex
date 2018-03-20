defmodule AdminPanel.PageController do
  use AdminPanel, :controller
  alias Plug.Conn

  @not_found_message """
    The assets are not available. If you think this is incorrect,
    please make sure that the front-end assets have been built.
    """

  def index(conn, _params) do
    index_path =
      case conn do
        %{private: %{override_dist_path: dist_path}} ->
          Path.join(dist_path, "index.html")
        _ ->
          dist_path = Application.get_env(:admin_panel, :dist_path)
          Path.join(dist_path, "index.html")
      end

    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Conn.send_file(200, index_path)
  rescue
    File.Error ->
      conn
      |> put_resp_header("content-type", "text/plain; charset=utf-8")
      |> Conn.send_resp(:not_found, @not_found_message)
  end
end
