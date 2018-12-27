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

defmodule UrlDispatcher.Plug do
  @moduledoc false
  import Plug.Conn, only: [resp: 3, halt: 1, put_status: 2]
  import Phoenix.Controller, only: [json: 2, redirect: 2]
  alias Plug.Static

  @public_folders ~w(uploads swagger)

  def init(options), do: options
  def call(conn, _opts), do: handle_request(conn.request_path, conn)

  defp handle_request("/", conn) do
    conn
    |> put_status(200)
    |> json(%{status: true, ewallet_version: Application.get_env(:ewallet, :version)})
  end

  defp handle_request("/admin" <> _, conn), do: AdminPanel.Endpoint.call(conn, [])
  defp handle_request("/api/client" <> _, conn), do: EWalletAPI.Endpoint.call(conn, [])
  defp handle_request("/api/admin" <> _, conn), do: AdminAPI.Endpoint.call(conn, [])
  defp handle_request("/pages/client" <> _, conn), do: EWalletAPI.Endpoint.call(conn, [])

  defp handle_request("/public" <> _, conn) do
    opts =
      Static.init(
        at: "/public",
        from: Path.join(Application.get_env(:ewallet, :root), "public"),
        only: @public_folders
      )

    static_call(conn, opts)
  end

  defp handle_request("/docs", conn), do: redirect(conn, to: "/docs/index.html")

  defp handle_request("/docs" <> _, conn) do
    opts =
      Static.init(
        at: "/docs",
        from: Path.join(Application.get_env(:ewallet, :root), "public/docs")
      )

    static_call(conn, opts)
  end

  defp handle_request(_, conn) do
    conn
    |> resp(404, "The url could not be resolved.")
    |> halt()
  end

  defp static_call(conn, opts) do
    case Static.call(conn, opts) do
      %{halted: true} = conn ->
        conn

      _ ->
        conn
        |> resp(404, "The url could not be resolved.")
        |> halt()
    end
  end
end
