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

defmodule EthOmisegoNetworkAdapter.HttpClient do
  @moduledoc """
  Simple HTTP client to perform request on the watcher's API
  """

  alias EthOmisegoNetworkAdapter.Config
  alias HTTPoison.Response

  @doc """
  Build, submit and parse the response of a call to the watcher's API.
  Returns
  {:ok, data} if success
  {:error, :omisego_network_connection_error} if unreachable
  {:error, omisego_network_bad_request, params} if bad response
  """
  @spec post_request(binary(), []) :: {:ok | :error, any()}
  def post_request(payload, action) do
    headers = [{"Content-Type", "application/json"}, {"accept", "application/json"}]
    path = Config.get_watcher_url() <> "/" <> action

    with {:ok, response} <- HTTPoison.post(path, payload, headers),
         %Response{body: body, status_code: code} = response do
      decode_body(body, code)
    else
      _error -> {:error, :omisego_network_connection_error}
    end
  end

  @spec decode_body(binary(), integer()) :: {:ok | :error, any()}
  defp decode_body(body, code) do
    with {:ok, decoded_body} <- Jason.decode(body) do
      case {code, decoded_body} do
        {200, %{"success" => true, "data" => data}} ->
          {:ok, data}

        {200,
         %{
           "success" => false,
           "data" => %{"object" => "error", "code" => code}
         }} ->
          {:error, :omisego_network_bad_request, error_code: code}

        _ ->
          {:error, :omisego_network_bad_request, error_code: "invalid response"}
      end
    else
      {:error, _error} -> {:error, :omisego_network_bad_request, error_code: "decoding error"}
    end
  end
end
