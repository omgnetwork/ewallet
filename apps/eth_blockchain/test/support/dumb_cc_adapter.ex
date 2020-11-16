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

defmodule EthBlockchain.DumbCCAdapter do
  @moduledoc false
  use GenServer

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, :ok, [])

  def init(_opts) do
    {:ok, %{}}
  end

  def stop(pid), do: GenServer.stop(pid)

  def handle_call({:get_deposit_tx_bytes, _address, _amount, _currency}, _from, state) do
    {:reply,
     {:ok,
      "0xf9010ff843b8415ea0db90e83afe73556dd195af2b014b1e7eb03003f3559e59988059469746650bfb0287a1b0901020fc5f782f742482708cbec61c40df74e4f2b010c36f56261bd2c58271488001c3808080c3808080c3808080f8b5eb94811ae0a85d3f86824da3abe49a2407ea55a8b05294000000000000000000000000000000000000000064f094811ae0a85d3f86824da3abe49a2407ea55a8b05394000000000000000000000000000000000000000085174876dbfceb94000000000000000000000000000000000000000094000000000000000000000000000000000000000080eb94000000000000000000000000000000000000000094000000000000000000000000000000000000000080"},
     state}
  end

  def handle_call({:get_childchain_framework_address}, _from, state) do
    {:reply, {:ok, "0xc673e4ffcb8464faff908a6804fe0e635af0ea2f"}, state}
  end

  def handle_call({:get_childchain_eth_vault_address}, _from, state) do
    {:reply, {:ok, "0x4e3aeff70f022a6d4cc5947423887e7152826cf7"}, state}
  end

  def handle_call({:get_childchain_erc20_vault_address}, _from, state) do
    {:reply, {:ok, "0x135505d9f4ea773dd977de3b2b108f2dae67b63a"}, state}
  end

  def handle_call({:get_childchain_payment_exit_game_address}, _from, state) do
    {:reply, {:ok, "0x89afce326e7da55647d22e24336c6a2816c99f6b"}, state}
  end

  def handle_call({:get_errors}, _from, state) do
    {:reply, %{}, state}
  end

  def handle_call({:get_transaction_receipt, "not_found"}, _from, reg) do
    {:reply, {:ok, :not_found}, reg}
  end

  def handle_call({:get_balance, _address}, _from, reg) do
    {:reply,
     {:ok,
      %{
        "0x0000000000000000000000000000000000000000" => 123,
        "0x0000000000000000000000000000000000000001" => 100
      }}, reg}
  end

  def handle_call({:get_transaction_receipt, transaction_hash}, _from, state) do
    receipt = %{
      eth_block: %{
        number: 2,
        hash: "0x86c72415cd59771eda3dec8b1d0904a2342f48555e46d17508b73a184024e1f7",
        timestamp: 1_566_981_001
      },
      cc_block_number: 30_000,
      inputs: [
        %{
          amount: 99_999_997_025,
          block_number: 29_000,
          currency: "0x0000000000000000000000000000000000000000",
          oindex: 1,
          owner: "0x811ae0a85d3f86824da3abe49a2407ea55a8b053",
          transaction_index: 0,
          utxo_position: 29_000_000_000_001
        }
      ],
      metadata: nil,
      outputs: [
        %{
          amount: 100,
          block_number: 30_000,
          currency: "0x0000000000000000000000000000000000000000",
          oindex: 0,
          owner: "0x811ae0a85d3f86824da3abe49a2407ea55a8b052",
          transaction_index: 0,
          utxo_position: 30_000_000_000_000
        },
        %{
          amount: 99_999_996_924,
          block_number: 30_000,
          currency: "0x0000000000000000000000000000000000000000",
          oindex: 1,
          owner: "0x811ae0a85d3f86824da3abe49a2407ea55a8b053",
          transaction_index: 0,
          utxo_position: 30_000_000_000_001
        }
      ],
      transaction_bytes:
        "0xf9010ff843b8415ea0db90e83afe73556dd195af2b014b1e7eb03003f3559e59988059469746650bfb0287a1b0901020fc5f782f742482708cbec61c40df74e4f2b010c36f56261bd2c58271488001c3808080c3808080c3808080f8b5eb94811ae0a85d3f86824da3abe49a2407ea55a8b05294000000000000000000000000000000000000000064f094811ae0a85d3f86824da3abe49a2407ea55a8b05394000000000000000000000000000000000000000085174876dbfceb94000000000000000000000000000000000000000094000000000000000000000000000000000000000080eb94000000000000000000000000000000000000000094000000000000000000000000000000000000000080",
      transaction_hash: transaction_hash,
      transaction_index: 0
    }

    {:reply, {:ok, :success, receipt}, state}
  end

  def handle_call({:send, _from_address, _to, _amount, _currency}, _from, state) do
    response = %{
      block_number: 123_000,
      transaction_index: 111,
      transaction_hash: "0xbdf562c24ace032176e27621073df58ce1c6f65de3b5932343b70ba03c72132d"
    }

    {:reply, {:ok, response}, state}
  end
end
