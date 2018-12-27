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

defmodule AdminAPI.V1.AdminAPIAuthPlug do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminAPIAuth

  def init(opts), do: opts

  def call(conn, _opts) do
    %{headers: conn.req_headers}
    |> AdminAPIAuth.authenticate()
    |> handle_auth_result(conn)
  end

  defp handle_auth_result(%{authenticated: false} = auth, conn) do
    conn
    |> assign(:authenticated, false)
    |> handle_error(auth[:auth_error])
  end

  defp handle_auth_result(
         %{authenticated: true, auth_scheme: :admin, admin_user: admin_user} = auth,
         conn
       ) do
    conn
    |> assign(:authenticated, true)
    |> assign(:auth_scheme, :admin)
    |> assign(:admin_user, admin_user)
    |> put_private(:auth_user_id, auth[:auth_user_id])
    |> put_private(:auth_auth_token, auth[:auth_auth_token])
  end

  defp handle_auth_result(%{authenticated: true, auth_scheme: :provider, key: key} = auth, conn) do
    conn
    |> assign(:authenticated, true)
    |> assign(:auth_scheme, :provider)
    |> assign(:key, key)
    |> put_private(:auth_access_key, auth[:auth_access_key])
    |> put_private(:auth_secret_key, auth[:auth_secret_key])
  end
end
