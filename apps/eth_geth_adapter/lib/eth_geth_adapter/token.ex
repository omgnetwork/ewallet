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

defmodule EthGethAdapter.Token do
  @moduledoc false

  import EthGethAdapter.ErrorHandler

  alias Ethereumex.HttpClient, as: Client

  @doc """

  """
  def get_field(contract_address, encoded_abi_data) do
    %{
      data: encoded_abi_data,
      to: contract_address
    }
    |> Client.eth_call()
    |> parse_response()
  end

  defp parse_response({:ok, _data} = response), do: response

  defp parse_response({:error, error}), do: handle_error(error)
end
