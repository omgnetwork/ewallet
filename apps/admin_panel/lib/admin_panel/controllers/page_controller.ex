defmodule AdminPanel.PageController do
  use AdminPanel, :controller
  alias Plug.Conn

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Conn.send_file(200, Application.app_dir(:admin_panel, "priv/dist/index.html"))
  end
end
