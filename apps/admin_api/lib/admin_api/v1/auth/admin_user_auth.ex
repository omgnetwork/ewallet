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

defmodule AdminAPI.V1.AdminUserAuth do
  @moduledoc """
  This module takes care of authenticating an admin user for websocket connections.
  """
  alias EWalletDB.{AuthToken, User}

  def authenticate(auth) do
    auth
    |> parse_header()
    |> authenticate_token()
  end

  defp parse_header(auth) do
    with header when not is_nil(header) <- auth[:auth_header],
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["OMGAdmin"],
         {:ok, decoded} <- Base.decode64(content),
         [user_id, auth_token] <- String.split(decoded, ":", parts: 2) do
      auth
      |> Map.put(:auth_user_id, user_id)
      |> Map.put(:auth_auth_token, auth_token)
    else
      _ ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)
    end
  end

  # Skip token auth if it already failed since API key validation or header parsing
  defp authenticate_token(%{authenticated: false} = auth), do: auth

  defp authenticate_token(auth) do
    user_id = auth[:auth_user_id]
    auth_token = auth[:auth_auth_token]

    case AuthToken.authenticate(user_id, auth_token, :admin_api) do
      %User{} = admin_user ->
        auth
        |> Map.put(:authenticated, true)
        |> Map.put(:admin_user, admin_user)

      false ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :auth_token_not_found)

      :token_expired ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :auth_token_expired)
    end
  end
end
