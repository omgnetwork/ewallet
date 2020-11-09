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
  alias ActivityLogger.System
  alias EWallet.BlockchainHelper
  alias EWalletDB.{BlockchainTransaction, BlockchainTransactionState}

  @rootchain_identifier BlockchainHelper.rootchain_identifier()
  @childchain_identifier BlockchainHelper.childchain_identifier()

  @spec transfer_on_childchain(map(), map(), String.t(), String.t()) ::
          {:error, atom(), String.t()}
  def transfer_on_childchain(
        %{
          from: from,
          to: to,
          amount: amount,
          currency: currency
        },
        originator,
        childchain_id,
        rootchain_id
      ) do
    with :ok <- validate_rootchain_identifier(rootchain_id),
         :ok <- validate_childchain_identifier(childchain_id),
         attrs <- %{
           from: from,
           to: to,
           amount: amount,
           currency: currency,
           childchain_identifier: String.to_existing_atom(childchain_id)
         } do
      :transfer_on_childchain
      |> BlockchainHelper.call(attrs)
      |> create_childchain_transaction(originator, childchain_id, rootchain_id)
    end
  end

  @spec transfer_on_rootchain(map(), map(), String.t()) ::
          {:ok, map()} | {:error, atom(), String.t()}
  def transfer_on_rootchain(
        %{
          from: _from,
          to: _to,
          amount: _amount,
          contract_address: _currency
        } = attrs,
        originator,
        rootchain_id
      ) do
    case validate_rootchain_identifier(rootchain_id) do
      :ok ->
        :send
        |> BlockchainHelper.call(attrs)
        |> create_rootchain_transaction(originator, rootchain_id)

      error ->
        error
    end
  end

  @spec deposit_to_childchain(map(), map(), String.t(), String.t()) ::
          {:ok, map()} | {:error, atom(), String.t()}
  def deposit_to_childchain(
        %{
          amount: amount,
          currency: currency,
          to: to
        },
        originator,
        childchain_id,
        rootchain_id
      ) do
    with :ok <- validate_rootchain_identifier(rootchain_id),
         :ok <- validate_childchain_identifier(childchain_id),
         attrs <- %{
           childchain_identifier: String.to_existing_atom(childchain_id),
           amount: amount,
           currency: currency,
           to: to
         } do
      :deposit_to_childchain
      |> BlockchainHelper.call(attrs)
      |> create_rootchain_transaction(originator, rootchain_id)
    end
  end

  @spec deploy_erc20_token(map(), String.t()) :: {:ok, map()} | {:error, atom(), String.t()}
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
    case validate_rootchain_identifier(rootchain_id) do
      :ok ->
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

      error ->
        error
    end
  end

  @spec mint_erc20_token(map(), String.t()) :: {:ok, map()} | {:error, atom(), String.t()}
  def mint_erc20_token(
        %{
          from: from,
          contract_address: contract_address,
          amount: amount
        },
        rootchain_id
      ) do
    case validate_rootchain_identifier(rootchain_id) do
      :ok ->
        attrs = %{
          from: from,
          contract_address: contract_address,
          amount: amount
        }

        :mint_erc20
        |> BlockchainHelper.call(attrs)
        |> parse_mint_erc20_response(rootchain_id)

      error ->
        error
    end
  end

  defp parse_mint_erc20_response(
         {:ok, %{gas_price: _gas_price, gas_limit: _gas_limit, tx_hash: _tx_hash}} = response,
         rootchain_id
       ) do
    # TODO: Put correct originator
    case create_rootchain_transaction(response, %System{}, rootchain_id) do
      {:ok, blockchain_transaction} ->
        {:ok, %{blockchain_transaction: blockchain_transaction}}

      error ->
        error
    end
  end

  defp parse_mint_erc20_response(error, _attrs), do: error

  defp parse_deploy_erc20_response(
         {:ok, %{contract_address: contract_address, contract_uuid: contract_uuid}} = response,
         rootchain_id
       ) do
    # TODO: Put correct originator
    case create_rootchain_transaction(response, %System{}, rootchain_id) do
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

  defp create_childchain_transaction(
         {:ok, %{tx_hash: tx_hash}},
         originator,
         childchain_id,
         rootchain_id
       ) do
    attrs = %{
      hash: tx_hash,
      rootchain_identifier: rootchain_id,
      childchain_identifier: childchain_id,
      status: BlockchainTransactionState.submitted(),
      originator: originator
    }

    BlockchainTransaction.insert_childchain(attrs)
  end

  defp create_childchain_transaction(error, _, _, _), do: error

  defp create_rootchain_transaction(
         {:ok,
          %{
            tx_hash: tx_hash,
            gas_price: gas_price,
            gas_limit: gas_limit
          }},
         originator,
         rootchain_id
       ) do
    attrs = %{
      hash: tx_hash,
      rootchain_identifier: rootchain_id,
      status: BlockchainTransactionState.submitted(),
      gas_price: gas_price,
      gas_limit: gas_limit,
      originator: originator
    }

    BlockchainTransaction.insert_outgoing_rootchain(attrs)
  end

  defp create_rootchain_transaction(error, _, _), do: error

  defp validate_rootchain_identifier(@rootchain_identifier), do: :ok

  defp validate_rootchain_identifier(_) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `roootchain_identifier` is invalid."}
  end

  defp validate_childchain_identifier(@childchain_identifier), do: :ok

  defp validate_childchain_identifier(_) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `childchain_identifier` is invalid."}
  end
end
