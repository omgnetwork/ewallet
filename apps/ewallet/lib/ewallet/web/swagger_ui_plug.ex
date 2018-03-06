defmodule EWallet.Web.SwaggerUIPlug do
  @moduledoc """
  A plug that renders the Swagger UI.
  """
  use Plug.Router
  import Plug.Conn

  plug :match
  plug :dispatch

  get "/", do: send_file(conn, 200, conn.private.swagger_ui_path)
  get "/openapi.yaml", do: send_file(conn, 200, conn.private.openapi_spec_path)
  get "/*_", do: conn |> resp(404, "File not found.") |> halt()

  def init(opts), do: opts

  def call(conn, opts) do
    otp_app  = Keyword.fetch!(opts, :otp_app)
    ui_path  = Path.join([Application.app_dir(:ewallet), "priv", "swagger.html"])
    spec_path = Path.join([Application.app_dir(otp_app), "priv", "openapi.yaml"])

    conn
    |> put_private(:swagger_ui_path, ui_path)
    |> put_private(:openapi_spec_path, spec_path)
    |> super([])
  end
end
