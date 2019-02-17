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

defmodule AdminPanel.PageController do
  use AdminPanel, :controller
  import Ecto.Query
  import EWalletDB.SoftDelete
  alias EWalletDB.{APIKey, Repo}
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
      |> inject_api_key()

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
    :admin_panel
    |> Application.get_env(:dist_path)
    |> Path.join("index.html")
  end

  defp inject_api_key(content) do
    String.replace(content, ~s("app"></div>), api_key_script(), insert_replaced: 0)
  end

  defp api_key_script do
    APIKey
    |> exclude_deleted()
    |> limit(1)
    |> Repo.get_by(%{owner_app: "admin_api"})
    |> api_key_script()
  end

  defp api_key_script(%APIKey{} = api_key) do
    """
    <script>
      var adminConfig = {};

      adminConfig.apiKeyId = "#{api_key.id}";
      adminConfig.apiKey = "#{api_key.key}";

      window.adminConfig = adminConfig;
    </script>
    """
  end

  # For troubleshooting purposes
  defp api_key_script(_), do: "<!-- No API key found -->"
end
