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

defmodule EthGethAdapter.Transaction do
  @moduledoc false

  alias Ethereumex.HttpClient, as: Client

  def send_raw(transaction_data) do
    transaction_data
    |> Client.eth_send_raw_transaction()
    |> parse_response()
  end

  def get_transaction_count(address) do
    Client.eth_get_transaction_count(address)
  end

  defp parse_response({:ok, _data} = response), do: response

  defp parse_response({:error, %{"message" => message}}) do
    {:error, :adapter_error, message}
  end
end
