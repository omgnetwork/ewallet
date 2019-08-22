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

defmodule EthElixirOmgAdapter.HttpClient do
  @moduledoc false

  alias EthElixirOmgAdapter.Config
  alias HTTPoison.Response

  @spec post_request(binary(), []) :: {:ok | :error, any()}
  def post_request(payload, action) do
    headers = [{"Content-Type", "application/json"}, {"accept", "application/json"}]
    path = Config.get_watcher_url() <> "/" <> action

    with {:ok, response} <- HTTPoison.post(path, payload, headers),
         %Response{body: body, status_code: code} = response do
      decode_body(body, code)
    else
      _error -> {:error, :elixir_omg_connection_error}
    end
  end

  @spec decode_body(binary(), integer()) :: {:ok | :error, any()}
  defp decode_body(body, code) do
    with {:ok, decoded_body} <- Jason.decode(body) do
      case {code, decoded_body} do
        {200,
         %{
           "success" => false,
           "data" => %{"object" => "error", "code" => code}
         }} ->
          {:error, :elixir_omg_bad_request, error_code: code}

        {200, %{"success" => true, "data" => data}} ->
          {:ok, data}

        _ ->
          {:error, :elixir_omg_bad_request, error_code: inspect(decoded_body)}
      end
    else
      {:error, error} -> {:error, :elixir_omg_bad_request, error_code: inspect(error)}
    end
  end
end
