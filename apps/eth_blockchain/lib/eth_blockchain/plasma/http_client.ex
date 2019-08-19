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

defmodule EthBlockchain.Plasma.HttpClient do
  @moduledoc false

  @spec post_request(binary(), []) :: {:ok | :error, any()}
  def post_request(payload, url) do
    headers = [{"Content-Type", "application/json"}, {"accept", "application/json"}]
    #TODO: get URL from config. --- url = url || Application.get_env(:..., ...)

    with {:ok, response} <- HTTPoison.post(url, payload, headers),
         %HTTPoison.Response{body: body, status_code: code} = response do
      decode_body(body, code)
    else

      #TODO: handle error
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      e -> {:error, e}
    end
  end

  @spec decode_body(binary(), integer()) :: {:ok | :error, any()}
  defp decode_body(body, code) do
    with {:ok, decoded_body} <- Jason.decode(body) do
      case {code, decoded_body} do
        {200, %{"success" => false, "data" => %{"object" => "error", "code" => code, "description" => description}}} = a ->
          IO.inspect(a)
          {:error, :bad_request, code}
        {200, %{"success" => true, "data" => data}} = a ->
          IO.inspect(a)
          {:ok, data}
        _ -> {:error, decoded_body}
      end
    else
      {:error, %Jason.DecodeError{data: ""}} -> {:error, :empty_response}
      {:error, error} -> {:error, :invalid_json}
    end
  end
end
