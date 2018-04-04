defmodule EWallet.Web.APIDocs.Controller do
  @moduledoc false
  use EWallet, :controller

  plug :put_layout, false

  @doc false
  @spec forward(Plug.Conn.t, map) :: Plug.Conn.t
  def forward(%{private: %{redirect_to: destination}} = conn, _attrs) do
    redirect conn, to: destination
  end

  @doc false
  @spec ui(Plug.Conn.t, map) :: Plug.Conn.t
  def ui(conn, _attrs) do
    ui_path =
      :ewallet
      |> Application.app_dir()
      |> Path.join("priv/swagger.html")

    send_file(conn, 200, ui_path)
  end

  @doc false
  @spec yaml(Plug.Conn.t, map) :: Plug.Conn.t
  def yaml(conn, _attrs) do
    spec_path =
      conn
      |> get_otp_app()
      |> Application.app_dir()
      |> Path.join("priv/spec.yaml")

    send_file(conn, 200, spec_path)
  end

  @doc false
  @spec errors_ui(Plug.Conn.t, map) :: Plug.Conn.t
  def errors_ui(conn, _attrs) do
    render(conn, EWallet.Web.ApiDocsView, "errors.html", app_name: get_app_name(conn),
                                                         errors: get_errors(conn))
  end

  @doc false
  @spec errors_yaml(Plug.Conn.t, map) :: Plug.Conn.t
  def errors_yaml(conn, _attrs) do
    conn
    |> put_resp_content_type("text/x-yaml")
    |> render(EWallet.Web.ApiDocsView, "errors.yaml", errors: get_errors(conn))
  end

  @doc false
  @spec errors_json(Plug.Conn.t, map) :: Plug.Conn.t
  def errors_json(conn, _attrs) do
    json(conn, get_errors(conn))
  end

  defp get_otp_app(conn), do: endpoint_module(conn).config(:otp_app)

  defp get_app_name(conn) do
    case get_otp_app(conn) do
      :admin_api   -> "Admin API"
      :ewallet_api -> "eWallet API"
    end
  end

  defp get_errors(conn) do
    case endpoint_module(conn).config(:error_handler) do
      nil           -> %{}
      error_handler -> error_handler.errors()
    end
  end
end
