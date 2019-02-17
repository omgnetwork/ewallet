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

defmodule AdminAPI.V1.AdminAPIAuth do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  alias AdminAPI.V1.{AdminUserAuth, ProviderAuth}

  def authenticate(params) do
    # auth is an agnostic replacement for the conn being passed around
    # in plugs. This is a map created here and filled with authentication
    # details that will be used either in socket auth directly or through
    # a plug to assign data to conn.
    auth = %{}

    (params["headers"] || params[:headers])
    |> Enum.into(%{})
    |> extract_auth_scheme(auth)
    |> do_authenticate()
  end

  defp extract_auth_scheme(headers, auth) do
    with header when not is_nil(header) <- headers["authorization"],
         [scheme, _content] <- String.split(header, " ", parts: 2) do
      auth
      |> Map.put(:auth_scheme_name, scheme)
      |> Map.put(:auth_header, header)
    else
      _error ->
        auth
    end
  end

  defp do_authenticate(%{auth_scheme_name: "OMGAdmin"} = auth) do
    auth
    |> Map.put(:auth_scheme, :admin)
    |> AdminUserAuth.authenticate()
  end

  defp do_authenticate(%{auth_scheme_name: "Basic"} = auth) do
    auth
    |> Map.put(:auth_scheme, :provider)
    |> ProviderAuth.authenticate()
  end

  defp do_authenticate(%{auth_scheme_name: "OMGProvider"} = auth) do
    auth
    |> Map.put(:auth_scheme, :provider)
    |> ProviderAuth.authenticate()
  end

  defp do_authenticate(auth) do
    auth
    |> Map.put(:authenticated, false)
    |> Map.put(:auth_error, :invalid_auth_scheme)
  end
end
