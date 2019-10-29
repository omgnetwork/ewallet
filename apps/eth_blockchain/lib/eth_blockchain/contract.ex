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

defmodule EthBlockchain.Contract do
  @moduledoc false

  alias EthBlockchain.{ABIEncoder, Transaction}

  @erc20_uuid "3681491a-e8d0-4219-a40a-53d9a47fe64a"

  @erc20_mintable_uuid "9e0340c0-9aa4-4a01-b280-d400bc2dca73"

  def locked_contract_uuid, do: @erc20_uuid
  def unlocked_contract_uuid, do: @erc20_mintable_uuid

  @doc """
  Format and submit an ERC20 contract creation transaction with the given data
  Returns {:ok, response_map} if success,
  {:error, code} || {:error, code, message} otherwise
  """
  def deploy_erc20(attrs, opts \\ [])

  def deploy_erc20(%{locked: false} = attrs, opts) do
    do_deploy(attrs, @erc20_mintable_uuid, opts)
  end

  def deploy_erc20(attrs, opts) do
    do_deploy(attrs, @erc20_uuid, opts)
  end

  defp do_deploy(
         %{
           from: from,
           name: name,
           symbol: symbol,
           decimals: decimals,
           initial_amount: initial_amount
         },
         contract_uuid,
         opts
       ) do
    data =
      "0x" <>
        get_binary(contract_uuid) <>
        ABIEncoder.encode_erc20_attrs(name, symbol, decimals, initial_amount)

    %{from: from, contract_data: data}
    |> Transaction.create_contract(opts)
    |> respond(contract_uuid)
  end

  defp respond({:ok, attrs}, contract_uuid) do
    {:ok, Map.put(attrs, :contract_uuid, contract_uuid)}
  end

  defp respond(error, _contract_uuid), do: error

  def get_binary(contract_uuid) do
    :eth_blockchain
    |> Application.app_dir()
    |> Path.join("priv/contracts.json")
    |> File.read!()
    |> Jason.decode!()
    |> Map.get(contract_uuid)
    |> Map.get("binary")
  end
end
