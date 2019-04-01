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

defmodule EWallet.Web.Config do
  @moduledoc """
  Provides a configuration function that are called during application startup.
  """

  @headers [
    "Authorization",
    "Content-Type",
    "Accept",
    "Origin",
    "User-Agent",
    "DNT",
    "Cache-Control",
    "X-Mx-ReqToken",
    "Keep-Alive",
    "X-Requested-With",
    "If-Modified-Since",
    "X-CSRF-Token",
    "OMGAdmin-Account-ID"
  ]

  @methods [
    "POST",
    "GET"
  ]

  @doc """
  Prepares the config that is accepted by CORSPlug.

  Note that calling this function when setting up a plug,
  e.g. `plug CORSPlug, Config.cors_plug_config()`, would call this function at compile-time.

  The only value that can be dynamic is :origin, which CORSPlug allows passing
  a function reference to be called at runtime. See: https://hexdocs.pm/cors_plug/
  """
  @spec cors_plug_config() :: Keyword.t()
  def cors_plug_config do
    [
      max_age: 86_400,
      origin: &__MODULE__.cors_origin/0,
      headers: @headers,
      methods: @methods
    ]
  end

  # This should be a private function but required to be public as it's passed into CORSPLug.
  @doc false
  @spec cors_origin() :: [String.t()]
  def cors_origin do
    :ewallet
    |> Application.get_env(:cors_origin)
    |> cors_plug_origin()
  end

  defp cors_plug_origin(nil), do: []

  defp cors_plug_origin(origins) do
    origins
    |> String.trim()
    |> String.split(~r{\s*,\s*})
  end
end
