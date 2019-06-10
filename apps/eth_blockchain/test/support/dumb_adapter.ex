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

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, :ok, [])
  def init(:ok), do: {:ok, nil}
  def stop(pid), do: GenServer.stop(pid)

  def handle_call({:get_balances, _address, contract_addresses, _abi, _block}, _from, reg) do
    balances = Map.new(contract_addresses, fn ca -> {ca, 123} end)
    {:reply, {:ok, balances}, reg}
  end

  def handle_call({:get_transaction_count, _address}, _from, reg) do
    {:reply, {:ok, "0x1"}, reg}
  end

  def handle_call({:send_raw, _data}, _from, reg) do
    tx_hash = "0xdeaf34bc128581fa11687705015d3cb10f3bb45c00d34c3e2172d9ef57ee984c"
    {:reply, {:ok, tx_hash}, reg}
  end
end
