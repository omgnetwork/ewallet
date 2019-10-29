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

  @invalid_erc20_contract "0x9080682a37961d3c814464e7ada1c7e1b4638a27"
  @high_transaction_count_address "0x811ae0a85d3f86824da3abe49a2407ea55a8b053"

  def invalid_erc20_contract_address, do: @invalid_erc20_contract
  def high_transaction_count_address, do: @high_transaction_count_address

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, :ok, [])

  def init(_opts) do
    {:ok, %{}}
  end

  def stop(pid), do: GenServer.stop(pid)

  def handle_call({:get_balances, nil, _contract_addresses, _abi, _block}, _from, reg) do
    {:reply, {:error, :invalid_address}, reg}
  end

  def handle_call({:get_balances, _address, contract_addresses, _abi, _block}, _from, reg) do
    # 0x7B == 123
    balances = Enum.into(contract_addresses, [], fn _ -> "0x7B" end)
    {:reply, {:ok, balances}, reg}
  end

  def handle_call({:get_transaction_count, @high_transaction_count_address, _block}, _from, reg) do
    {:reply, {:ok, "0x64"}, reg}
  end

  def handle_call({:get_transaction_count, _address, _block}, _from, reg) do
    {:reply, {:ok, "0x0"}, reg}
  end

  def handle_call({:get_block_number}, _from, reg) do
    # 0xe == 14
    {:reply, {:ok, "0xe"}, reg}
  end

  def handle_call({:get_block, 0}, _from, reg) do
    {:reply,
     {:ok,
      %{
        "transactions" => []
      }}, reg}
  end

  def handle_call({:get_block, 1}, _from, reg) do
    {:reply, {:ok, nil}, reg}
  end

  def handle_call({:get_transaction_receipt, "not_found"}, _from, reg) do
    {:reply, {:ok, :not_found, nil}, reg}
  end

  def handle_call({:get_transaction_receipt, "failed"}, _from, reg) do
    receipt = %{
      block_hash: "0xead7d63c2e78b7a35ff9d9b7b75c1945c1a7cce657fdcf01ea4c75dbcc915f62",
      block_number: 4_458,
      contract_address: nil,
      cumulative_gas_used: 30_000,
      from: "0x7de7570b0b7d6ca94fb48c82dfeb61a193aa336d",
      gas_used: 3_300_000_000,
      logs: [],
      logs_bloom:
        "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      status: 0,
      to: "0x36c8dcfe2e42048e35bfe22e0ae969ce74223d5c",
      transaction_hash: "failed",
      transaction_index: 0
    }

    {:reply, {:ok, :failed, receipt}, reg}
  end

  # Custom tx hash with specific block number required by `EthBlockchain.DumbReceivingAdapter`
  def handle_call({:get_transaction_receipt, "01"}, _from, reg), do: receipt("01", 0, reg)
  def handle_call({:get_transaction_receipt, "02"}, _from, reg), do: receipt("02", 0, reg)
  def handle_call({:get_transaction_receipt, "03"}, _from, reg), do: receipt("03", 0, reg)
  def handle_call({:get_transaction_receipt, "04"}, _from, reg), do: receipt("04", 0, reg)
  def handle_call({:get_transaction_receipt, "05"}, _from, reg), do: receipt("05", 0, reg)
  def handle_call({:get_transaction_receipt, "11"}, _from, reg), do: receipt("11", 1, reg)
  def handle_call({:get_transaction_receipt, "12"}, _from, reg), do: receipt("12", 1, reg)
  def handle_call({:get_transaction_receipt, "13"}, _from, reg), do: receipt("13", 1, reg)
  def handle_call({:get_transaction_receipt, "14"}, _from, reg), do: receipt("14", 1, reg)
  def handle_call({:get_transaction_receipt, "21"}, _from, reg), do: receipt("21", 2, reg)
  def handle_call({:get_transaction_receipt, tx_hash}, _from, reg), do: receipt(tx_hash, 2, reg)

  def handle_call({:send_raw, _data}, _from, reg) do
    data = 32 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
    {:reply, {:ok, "0x" <> data}, reg}
  end

  # name
  def handle_call({:get_field, @invalid_erc20_contract, "0x06fdde03"}, _from, reg) do
    {:reply, {:ok, "0x"}, reg}
  end

  def handle_call({:get_field, _, "0x06fdde03"}, _from, reg) do
    {:reply,
     {:ok,
      "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000084f4d47546f6b656e000000000000000000000000000000000000000000000000"},
     reg}
  end

  # decimals
  def handle_call({:get_field, @invalid_erc20_contract, "0x313ce567"}, _from, reg) do
    {:reply, {:ok, "0x"}, reg}
  end

  def handle_call({:get_field, _, "0x313ce567"}, _from, reg) do
    {:reply, {:ok, "0x0000000000000000000000000000000000000000000000000000000000000012"}, reg}
  end

  # total supply
  def handle_call({:get_field, @invalid_erc20_contract, "0x18160ddd"}, _from, reg) do
    {:reply, {:ok, "0x"}, reg}
  end

  def handle_call({:get_field, _, "0x18160ddd"}, _from, reg) do
    {:reply, {:ok, "0x0000000000000000000000000000000000000000000000056bc75e2d63100000"}, reg}
  end

  # symbol
  def handle_call({:get_field, @invalid_erc20_contract, "0x95d89b41"}, _from, reg) do
    {:reply, {:ok, "0x"}, reg}
  end

  def handle_call({:get_field, _, "0x95d89b41"}, _from, reg) do
    {:reply,
     {:ok,
      "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000034f4d470000000000000000000000000000000000000000000000000000000000"},
     reg}
  end

  # minting finished
  def handle_call({:get_field, _, "0x05d2035b"}, _from, reg) do
    # "0x05d2035b" is the hex encoded value of the ABI encoded "finishMinting()"
    {:reply, {:ok, "0x0000000000000000000000000000000000000000000000000000000000000001"}, reg}
  end

  def handle_call({:get_eth_syncing}, _from, reg) do
    {:reply, {:ok, false}, reg}
  end

  def handle_call({:get_client_version}, _from, reg) do
    {:reply, {:ok, "DumbAdapter/v4.2.0-c999068/linux/go1.9.2"}, reg}
  end

  def handle_call({:get_network_id}, _from, reg) do
    # Yes, network id is a string.
    {:reply, {:ok, "99"}, reg}
  end

  def handle_call({:get_peer_count}, _from, reg) do
    # 0x2a == 42
    {:reply, {:ok, "0x2a"}, reg}
  end

  def handle_call({:get_errors}, _from, reg) do
    {:reply, %{}, reg}
  end

  defp receipt(tx_hash, block_number, reg) do
    receipt = %{
      block_hash: "0xaa21ae024ddf50fd7753bf75ea7646bfc505cb96f36ad6af00159f20be93eda1",
      block_number: block_number,
      contract_address: nil,
      cumulative_gas_used: 21_000,
      from: "0x47b7dabe049b5daec98048851494c8548066dc77",
      gas_used: 21_000,
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
end
