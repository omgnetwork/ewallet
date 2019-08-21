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
  import Utils.Helpers.Encoding
  alias EthBlockchain.{Adapter, Helper, Transaction}

  @eth EthBlockchain.Helper.default_address()

  def deposit(
        %{
          to: to,
          amount: amount,
          currency: currency,
          childchain_identifier: childchain_identifier
        } = attrs,
        eth_adapter \\ nil,
        eth_pid \\ nil,
        cc_adapter \\ nil,
        cc_pid \\ nil
      ) do
    with :ok <- check_childchain(childchain_identifier) do
      contract_address = Adapter.childchain_call({:get_contract_address}, cc_adapter, cc_pid)

      {:get_deposit_tx_bytes, to, amount, currency}
      |> Adapter.childchain_call(cc_adapter, cc_pid)
      |> submit_deposit(to, amount, currency, contract_address, eth_adapter, eth_pid)
    end
  end

  defp submit_deposit(tx_bytes, to, amount, token \\ @eth, adapter, pid)

  defp submit_deposit(tx_bytes, to, amount, @eth, contract_address, adapter, pid) do
    Transaction.deposit_eth(
      %{tx_bytes: tx_bytes, from: to, amount: amount, contract_address: contract_address},
      adapter,
      pid
    )
  end

  defp submit_deposit(tx_bytes, to, amount, erc20, root_chain_contract, eth_adapter, eth_pid) do
    with {:ok, _tx_hash} <-
           Transaction.approve_erc20(
             %{
               from: to,
               to: root_chain_contract,
               amount: amount,
               contract_address: erc20
             },
             eth_adapter,
             eth_pid
           ),
         {:ok, _tx_hash} = response <-
           Transaction.deposit_erc20(
             %{
               tx_bytes: tx_bytes,
               from: to,
               amount: amount,
               root_chain_contract: root_chain_contract,
               erc20_contract: erc20
             },
             eth_adapter,
             eth_pid
           ) do
      response
    end
  end

  def send(
        %{
          from: from,
          to: to,
          amount: amount,
          currency: currency,
          childchain_identifier: childchain_identifier
        } = attrs,
        cc_adapter \\ nil,
        cc_pid \\ nil
      ) do
    with :ok <- check_childchain(childchain_identifier) do
      Adapter.childchain_call({:send, from, to, amount, currency}, cc_adapter, cc_pid)
    end
  end

  defp check_childchain(childchain_identifier) do
    case :eth_blockchain
         |> Application.get_env(EthBlockchain.Adapter)
         |> Keyword.get(:childchain_adapters)
         |> Enum.find(fn {id, _} -> id == childchain_identifier end) do
      nil ->
        {:error, :childchain_not_supported}

      cc ->
        :ok
    end
  end

  def get_block do
    # TODO: get block and parse transactions to find relevant ones
    # to be used by a childchain AddressTracker
  end

  def get_exitable_utxos do
    # TODO: Check if childchain is supported
    # TODO: Retrieve exitable utxos from Watcher API
  end

  def exit(
        %{childchain_identifier: childchain_identifier, address: address, utxos: utxos} = attrs,
        adapter \\ nil,
        pid \\ nil
      ) do
    # TODO: 1. Check if childchain is supported
    # TODO: 2. Attempt to exit all given utxos
  end
end
