# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule Frontend.PageController do
  use Frontend, :controller
  alias Plug.Conn

  @not_found_message """
  The assets are not available. If you think this is incorrect,
  please make sure that the front-end assets have been built.
  """

  def index(conn, _params) do
    content =
      conn
      |> index_file_path()
      |> File.read!()

    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Conn.send_resp(200, content)
  rescue
    File.Error ->
      conn
      |> put_resp_header("content-type", "text/plain; charset=utf-8")
      |> Conn.send_resp(:not_found, @not_found_message)
  end

  defp index_file_path(%{private: %{override_dist_path: dist_path}}) do
    Path.join(dist_path, "index.html")
  end

  defp index_file_path(_conn) do
    :frontend
    |> Application.get_env(:dist_path)
    |> Path.join("index.html")
  end
end
