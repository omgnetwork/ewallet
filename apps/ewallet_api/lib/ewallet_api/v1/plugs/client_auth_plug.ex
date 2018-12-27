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

defmodule EWalletAPI.V1.ClientAuthPlug do
  @moduledoc """
  This plug checks if valid api key and token were provided.

  If api key and token are valid, the plug assigns the user
  associated with the token to the connection so that downstream
  consumers know which user this request belongs to.
  """
  import Plug.Conn
  import EWalletAPI.V1.ErrorHandler
  alias EWalletAPI.V1.ClientAuth
  alias EWallet.Web.Originator
  alias EWalletDB.AuthToken

  def init(opts), do: opts

  def call(conn, _opts) do
    %{headers: conn.req_headers}
    |> ClientAuth.authenticate()
    |> handle_auth_result(conn)
  end

  defp handle_auth_result(%{authenticated: false} = auth, conn) do
    conn
    |> assign(:authenticated, false)
    |> handle_error(auth[:auth_error])
  end

  defp handle_auth_result(%{authenticated: true} = auth, conn) do
    conn
    |> assign(:authenticated, true)
    |> assign(:auth_scheme, :client)
    |> assign(:end_user, auth[:end_user])
    |> put_private(:auth_api_key, auth[:auth_api_key])
    |> put_private(:auth_auth_token, auth[:auth_auth_token])
  end

  @doc """
  Expires the authentication token used in this connection.
  """
  def expire_token(conn) do
    token_string = conn.private[:auth_auth_token]
    originator = Originator.extract(conn.assigns)

    AuthToken.expire(token_string, :ewallet_api, originator)

    conn
    |> assign(:authenticated, false)
    |> assign(:end_user, nil)
  end
end
