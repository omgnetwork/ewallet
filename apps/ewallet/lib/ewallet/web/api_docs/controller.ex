# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  @spec yaml(Plug.Conn.t(), map) :: Plug.Conn.t()
  def yaml(conn, _attrs) do
    spec_path =
      conn
      |> get_otp_app()
      |> Application.app_dir()
      |> Path.join("priv/spec.yaml")

    send_file(conn, 200, spec_path)
  end

  @doc false
  @spec json(Plug.Conn.t(), map) :: Plug.Conn.t()
  def json(conn, _attrs) do
    spec_path =
      conn
      |> get_otp_app()
      |> Application.app_dir()
      |> Path.join("priv/spec.json")

    send_file(conn, 200, spec_path)
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
end
