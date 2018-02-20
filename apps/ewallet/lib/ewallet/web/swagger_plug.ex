defmodule EWallet.Web.SwaggerPlug do
  @moduledoc """
  A plug that renders the Swagger UI.
  """
  use Plug.Router
  import Plug.Conn

  plug :match
  plug :dispatch

  get "/", do: send_file(conn, 200, conn.private.swagger_ui_path)
  get "/swagger.yaml", do: send_file(conn, 200, conn.private.swagger_doc_path)

  def init(opts), do: opts

  def call(conn, opts) do
    otp_app  = Keyword.fetch!(opts, :otp_app)
    ui_path  = Path.join([Application.app_dir(:ewallet), "priv", "swagger.html"])
    doc_path = Path.join([Application.app_dir(otp_app), "priv", "swagger.yaml"])

    conn
    |> put_private(:swagger_ui_path, ui_path)
    |> put_private(:swagger_doc_path, doc_path)
    |> super([])
  end
end
