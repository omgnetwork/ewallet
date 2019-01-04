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

defmodule EWalletAPI.VersionedRouter do
  @moduledoc """
  A router plug that attempts to figure out the requested API version,
  routes to the router for the specified version, and handles invalid
  version.
  """
  import Plug.Conn
  import EWalletAPI.V1.ErrorHandler

  def init(opts), do: opts

  @doc """
  Attempts to retrieve requested version,
  and routes to respective router for that version.
  """
  def call(conn, opts) do
    [accept] = get_req_header(conn, "accept")

    # Call the respected version of the router if mapping found,
    # raise an error otherwise.
    case get_accept_version(accept) do
      {:ok, router_module} ->
        dispatch_to_router(conn, opts, router_module)

      _ ->
        handle_invalid_version(conn, accept)
    end
  end

  defp get_accept_version(accept) do
    api_version = Application.get_env(:ewallet_api, :api_versions)

    case Map.fetch(api_version, accept) do
      {:ok, version} ->
        {:ok, version[:router]}

      _ ->
        :error
    end
  end

  defp dispatch_to_router(conn, opts, router_module) do
    opts = apply(router_module, :init, [opts])
    apply(router_module, :call, [conn, opts])
  end

  defp handle_invalid_version(conn, accept) do
    handle_error(conn, :invalid_version, %{"accept" => accept})
  end
end
