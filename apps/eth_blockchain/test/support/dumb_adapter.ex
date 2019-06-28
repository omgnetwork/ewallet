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

defmodule EthBlockchain.DumbAdapter do
  @moduledoc false
  use GenServer

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, :ok, [])

  def init(:ok) do
    {:ok, %{}}
  end

  def stop(pid), do: GenServer.stop(pid)

  def handle_call({:get_balances, nil, _contract_addresses, _abi, _block}, _from, reg) do
    {:reply, {:error, :invalid_address}, reg}
  end

  def handle_call({:get_balances, _address, contract_addresses, _abi, _block}, _from, reg) do
    balances = Map.new(contract_addresses, fn ca -> {ca, 123} end)
    {:reply, {:ok, balances}, reg}
  end

  def handle_call({:get_transaction_count, _address}, _from, reg) do
    {:reply, {:ok, "0x1"}, reg}
  end

  def handle_call({:get_block_number}, _from, reg) do
    {:reply, 14, reg}
  end

  def handle_call({:get_transaction_receipt, tx_hash}, _from, reg) do
    receipt = %{
      block_hash: "0xaa21ae024ddf50fd7753bf75ea7646bfc505cb96f36ad6af00159f20be93eda1",
      block_number: 2,
      contract_address: nil,
      cumulative_gas_used: 21000,
      from: "0x47b7dabe049b5daec98048851494c8548066dc77",
      gas_used: 21000,
      logs: [],
      logs_bloom:
        "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      status: 1,
      to: "0xa3dc43cb32b86b8add0e704d8db4ba6f1680a634",
      transaction_hash: tx_hash,
      transaction_index: 0
    }

    {:reply, {:ok, :success, receipt}, reg}
  end

  def handle_call({:send_raw, data}, _from, reg) do
    # Here we just pass the encoded data in the response for testing purpose.
    # When doing a real transaction, this will not be the case,
    # the transaction hash will be returned instead.
    {:reply, {:ok, data}, reg}
  end
end
