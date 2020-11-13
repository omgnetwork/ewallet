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

defmodule EthBlockchain.Childchain do
  @moduledoc false
  alias EthBlockchain.{AdapterServer, Helper, Transaction}

  @eth Helper.default_address()

  @doc """
  Submits a deposit transaction to the plasma chain.
  For ERC20 deposits, an `approve(address, amount)` call will be made
  first, then the deposit will be done.
  Returns
  {:ok, tx_hash} if success
  {:error, code} || {:error, code, params} if failure
  """
  @spec deposit(map(), list() | nil) :: {:ok, String.t()}
  def deposit(
        %{
          to: to,
          amount: amount,
          currency: currency,
          childchain_identifier: childchain_identifier
        },
        opts \\ []
      ) do
    with :ok <- check_childchain(childchain_identifier),
         # TODO: this is broken with new config, :get_contract_address does not exist anymore,
         # need to use the eth or erc20 vaults instead
         # (:get_childchain_eth_vault_address or :get_childchain_erc20_vault_address)
         {:ok, contract_address} <- AdapterServer.childchain_call({:get_contract_address}, opts),
         {:ok, tx_bytes} <-
           AdapterServer.childchain_call({:get_deposit_tx_bytes, to, amount, currency}, opts) do
      submit_deposit(tx_bytes, to, amount, currency, contract_address, opts)
    end
  end

  defp submit_deposit(tx_bytes, to, amount, @eth, root_chain_contract, opts) do
    Transaction.deposit_eth(
      %{tx_bytes: tx_bytes, from: to, amount: amount, root_chain_contract: root_chain_contract},
      opts
    )
  end

  defp submit_deposit(tx_bytes, to, amount, erc20, root_chain_contract, opts) do
    with {:ok, _attrs} <-
           Transaction.approve_erc20(
             %{
               from: to,
               to: root_chain_contract,
               amount: amount,
               contract_address: erc20
             },
             opts
           ),
         {:ok, _attrs} = response <-
           Transaction.deposit_erc20(
             %{
               tx_bytes: tx_bytes,
               from: to,
               root_chain_contract: root_chain_contract
             },
             opts
           ) do
      response
    end
  end

  @doc """
  Submits a transfer transaction to the plasma chain.

  Returns
  {:ok, %{tx_hash: transaction_hash, cc_block_number: block_number, cc_tx_index: transaction_index}} if success
  {:error, code} || {:error, code, params} if failure
  """
  @spec send(map(), list() | nil) :: {:ok, String.t(), integer(), integer()}
  def send(
        %{
          from: from,
          to: to,
          amount: amount,
          currency: currency,
          childchain_identifier: childchain_identifier
        },
        opts \\ []
      ) do
    with :ok <- check_childchain(childchain_identifier),
         {:ok,
          %{
            block_number: block_number,
            transaction_index: transaction_index,
            transaction_hash: transaction_hash
          }} <-
           AdapterServer.childchain_call({:send, from, to, amount, currency}, opts) do
      {:ok,
       %{tx_hash: transaction_hash, cc_block_number: block_number, cc_tx_index: transaction_index}}
    end
  end

  defp check_childchain(childchain_identifier) do
    :eth_blockchain
    |> Application.get_env(EthBlockchain.Adapter)
    |> Keyword.get(:cc_node_adapters)
    |> Enum.find(fn {id, _} -> id == childchain_identifier end)
    |> case do
      nil ->
        {:error, :childchain_not_supported}

      _cc ->
        :ok
    end
  end

  def get_transaction_receipt(%{tx_hash: tx_hash}, opts \\ []) do
    AdapterServer.childchain_call({:get_transaction_receipt, tx_hash}, opts)
  end

  def get_balance(%{address: address}, opts \\ []) do
    AdapterServer.childchain_call({:get_balance, address}, opts)
  end
end
