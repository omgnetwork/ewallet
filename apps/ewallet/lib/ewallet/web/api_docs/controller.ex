defmodule EWallet.Web.APIDocs.Controller do
  @moduledoc false
  use EWallet, :controller
  alias Phoenix.Controller
  plug(:put_layout, false)

  @doc false
  @spec forward(Plug.Conn.t(), map) :: Plug.Conn.t()
  def forward(%{private: %{redirect_to: destination}} = conn, _attrs) do
    redirect(conn, to: destination)
  end

  @doc false
  @spec ui(Plug.Conn.t(), map) :: Plug.Conn.t()
  def ui(conn, _attrs) do
    ui_path =
      :ewallet
      |> Application.app_dir()
      |> Path.join("priv/swagger.html")

    send_file(conn, 200, ui_path)
  end

  @doc false
  @spec swagger_subspec(Plug.Conn.t(), map) :: Plug.Conn.t()
  def swagger_subspec(
        %{request_path: path, private: %{redirect_to: destination}} = conn,
        _attrs
      ) do
    case Regex.run(~r/(json|yaml)$/, path) do
      nil -> redirect(conn, to: destination)
      match -> format_and_send(conn, Enum.at(match, 0))
    end
  end

  @doc false
  @spec json(Plug.Conn.t(), map) :: Plug.Conn.t()
  def json(conn, _attrs) do
    format_and_send(conn, "json")
  end

  @doc false
  @spec errors_ui(Plug.Conn.t(), map) :: Plug.Conn.t()
  def errors_ui(conn, _attrs) do
    render(
      conn,
      EWallet.Web.ApiDocsView,
      "errors.html",
      app_name: get_app_name(conn),
      errors: get_errors(conn)
    )
  end

  @doc false
  @spec errors_yaml(Plug.Conn.t(), map) :: Plug.Conn.t()
  def errors_yaml(conn, _attrs) do
    conn
    |> put_resp_content_type("text/x-yaml")
    |> render(EWallet.Web.ApiDocsView, "errors.yaml", errors: get_errors(conn))
  end

  @doc false
  @spec errors_json(Plug.Conn.t(), map) :: Plug.Conn.t()
  def errors_json(conn, _attrs) do
    conn
    |> put_resp_content_type("application/json")
    |> Controller.json(get_errors(conn))
  end

  defp get_otp_app(conn), do: endpoint_module(conn).config(:otp_app)

  defp get_app_name(conn) do
    case get_otp_app(conn) do
      :admin_api -> "Admin API"
      :ewallet_api -> "eWallet API"
    end
  end

  defp get_errors(conn) do
    case endpoint_module(conn).config(:error_handler) do
      nil -> %{}
      error_handler -> error_handler.errors()
    end
  end

  @doc false
  @spec format_and_send(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp format_and_send(%{private: %{redirect_to: destination}} = conn, extension)
       when extension == "yaml" or extension == "json" do
    spec_path =
      conn
      |> file_path(extension)
      |> spec_path(conn)
    try do
      send_file(conn, 200, spec_path)
    rescue
      _ -> redirect(conn, to: destination)
    end
  end

  @spec file_path(Plug.Conn.t(), String.t()) :: String.t()
  defp file_path(conn, extension) when extension == "yaml" or extension == "json" do
    file_path =
      conn.path_info
      |> Enum.drop(2)
      |> Enum.join("/")
      |> String.replace_leading("docs.#{extension}", "spec.#{extension}")

    "priv/" <> file_path
  end

  @spec spec_path(String.t(), Plug.Conn.t()) :: String.t()
  defp spec_path(file_path, conn) do
    conn
    |> get_otp_app()
    |> Application.app_dir()
    |> Path.join(file_path)
  end
end
