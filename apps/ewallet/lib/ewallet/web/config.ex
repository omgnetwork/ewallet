# Copyright 2019 OmiseGO Pte Ltd
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

  def configure_cors_plug do
    max_age =
      case System.get_env("CORS_MAX_AGE") do
        nil -> 600
        value -> String.to_integer(value)
      end

    cors_origin = System.get_env("CORS_ORIGIN")

    Application.put_env(:cors_plug, :max_age, max_age)
    Application.put_env(:cors_plug, :headers, @headers)
    Application.put_env(:cors_plug, :methods, ["POST"])
    Application.put_env(:cors_plug, :origin, cors_plug_origin(cors_origin))

    :ok
  end

  defp cors_plug_origin(nil), do: []

  defp cors_plug_origin(origins) do
    origins
    |> String.trim()
    |> String.split(~r{\s*,\s*})
  end
end
