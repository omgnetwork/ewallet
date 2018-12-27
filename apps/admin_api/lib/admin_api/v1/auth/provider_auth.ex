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

defmodule AdminAPI.V1.ProviderAuth do
  @moduledoc """
  This module takes care of authenticating a provider for websocket connections.
  """
  alias EWalletDB.Key

  def authenticate(auth) do
    auth
    |> parse_header()
    |> authenticate_access()
  end

  defp parse_header(auth) do
    with header when not is_nil(header) <- auth[:auth_header],
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGProvider"],
         {:ok, decoded} <- Base.decode64(content),
         [access, secret] <- String.split(decoded, ":", parts: 2) do
      auth
      |> Map.put(:auth_access_key, access)
      |> Map.put(:auth_secret_key, secret)
    else
      _ ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)
    end
  end

  # Skip auth if it already failed since header parsing
  defp authenticate_access(%{authenticated: false} = auth), do: auth

  defp authenticate_access(auth) do
    access_key = auth[:auth_access_key]
    secret_key = auth[:auth_secret_key]

    case Key.authenticate(access_key, secret_key) do
      {:ok, key} ->
        auth
        |> Map.put(:authenticated, true)
        |> Map.put(:key, key)

      false ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_access_secret_key)
    end
  end
end
