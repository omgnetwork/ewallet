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

defmodule AdminAPI.AssetNotFoundPlug do
  @moduledoc """
  This plug checks if the current request is for an asset and returns 404 if
  it was not found.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    check_asset(conn, {conn.method, Enum.at(conn.path_info, 0)})
  end

  defp check_asset(conn, {"GET", "public"}) do
    conn
    |> send_resp(404, "")
    |> halt()
  end

  defp check_asset(conn, _), do: conn
end
