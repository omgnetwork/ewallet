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

defmodule EWallet.BlockchainTransactionGate do
  @moduledoc """
  This module is a gate to the blockchain, it'll call the blockchain and
  insert a BlockchainTransaction.
  """

  def transfer_on_childchain(
        %{
          from: from,
          to: to,
          amount: amount,
          currency: currency
        },
        childchain_id,
        rootchain_id
      ) do
    attrs = %{
      from: from,
      to: to,
      amount: amount,
      currency: currency,
      childchain_identifier: String.to_existing_atom(childchain_id)
    }

    :transfer_on_childchain
    |> BlockchainHelper.call(attrs)
    |> create_childchain_transaction(childchain_id, rootchain_id)
  end

  def transfer_on_rootchain(
        %{
          from: from,
          to: to,
          amount: amount,
          currency: currency
        },
        rootchain_id
      ) do
    attrs = %{
      from: from,
      to: to,
      amount: amount,
      contract_address: currency
    }

    :send
    |> BlockchainHelper.call(attrs)
    |> create_rootchain_transaction(rootchain_id)
  end

  def deposit_to_childchain(
        %{
          amount: amount,
          currency: currency,
          to: to
        },
        childchain_id,
        rootchain_id
      ) do
    attrs = %{
      childchain_identifier: String.to_existing_atom(childchain_id),
      amount: amount,
      currency: currency,
      to: to
    }

    :deposit_to_childchain
    |> BlockchainHelper.call(attrs)
    |> create_rootchain_transaction(rootchain_id)
  end

  def deploy_erc20_token(
        %{
          from: from,
          name: name,
          symbol: symbol,
          decimals: decimals,
          initial_amount: amount,
          locked: locked
        },
        rootchain_id
      ) do
    attrs = %{
      from: from,
      name: name,
      symbol: symbol,
      decimals: decimals,
      initial_amount: amount,
      locked: locked
    }

    :deploy_erc20
    |> BlockchainHelper.call(attrs)
    |> parse_deploy_erc20_response(rootchain_id)
  end

  defp parse_deploy_erc20_response(
         {:ok, %{contract_address: contract_address, contract_uuid: contract_uuid} = response},
         rootchain_id
       ) do
    case create_rootchain_transaction(response, rootchain_id) do
      {:ok, blockchain_transaction} ->
        {:ok,
         %{
           contract_address: contract_address,
           contract_uuid: contract_uuid,
           blockchain_transaction: blockchain_transaction
         }}

      error ->
        error
    end
  end

  defp parse_deploy_erc20_response(error, _attrs), do: error

  defp create_childchain_transaction({:ok, %{tx_hash: tx_hash}}, childchain_id, rootchain_id) do
    attrs = %{
      hash: tx_hash,
      rootchain_identifier: rootchain_id,
      childchain_identifier: childchain_id,
      status: BlockchainTransactionState.submitted(),
      originator: %System{}
    }

    BlockchainTransaction.insert_childchain(attrs)
  end

  defp create_childchain_transaction(error, _, _), do: error

  defp create_rootchain_transaction(
         {:ok,
          %{
            tx_hash: tx_hash,
            gas_price: gas_price,
            gas_limit: gas_limit
          }},
         rootchain_id
       ) do
    attrs = %{
      hash: tx_hash,
      rootchain_identifier: rootchain_id,
      status: BlockchainTransactionState.submitted(),
      gas_price: gas_price,
      gas_limit: gas_limit,
      originator: %System{}
    }

    BlockchainTransaction.insert_rootchain(attrs)
  end

  defp create_rootchain_transaction(error, _), do: error
end
