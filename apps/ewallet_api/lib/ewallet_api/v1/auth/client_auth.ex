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

defmodule EWalletAPI.V1.ClientAuth do
  @moduledoc """
  This module takes care of authenticating a client for websocket connections.
  """
  alias EWalletDB.{APIKey, AuthToken, User}

  def authenticate(params) do
    # auth is an agnostic replacement for the conn being passed around
    # in plugs. This is a map created here and filled with authentication
    # details that will be used either in socket auth directly or through
    # a plug to assign data to conn.
    auth = %{}

    (params["headers"] || params[:headers])
    |> Enum.into(%{})
    |> parse_header(auth)
    |> authenticate_client()
    |> authenticate_token()
  end

  defp parse_header(headers, auth) do
    with header when not is_nil(header) <- headers["authorization"],
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGClient"],
         {:ok, decoded} <- Base.decode64(content),
         [key, token] <- String.split(decoded, ":", parts: 2) do
      auth
      |> Map.put(:auth_api_key, key)
      |> Map.put(:auth_auth_token, token)
    else
      _ ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)
    end
  end

  # Skip client auth if it already failed since header parsing
  defp authenticate_client(%{authenticated: false} = auth), do: auth

  defp authenticate_client(auth) do
    api_key = auth[:auth_api_key]

    case APIKey.authenticate(api_key) do
      false ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_api_key)

      api_key ->
        auth
        |> Map.put(:api_key, api_key)
    end
  end

  # Skip token auth if it already failed since API key validation
  defp authenticate_token(%{authenticated: false} = auth), do: auth

  defp authenticate_token(auth) do
    auth_token = auth[:auth_auth_token]

    case AuthToken.authenticate(auth_token, :ewallet_api) do
      %User{} = user ->
        auth
        |> Map.put(:authenticated, true)
        |> Map.put(:end_user, user)

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
