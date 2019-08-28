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

defmodule EthBlockchain.DumbReceivingAdapter do
  @moduledoc false
  use GenServer
  import Utils.Helpers.Encoding
  alias EthBlockchain.ABIEncoder
  alias Utils.Helpers.Crypto

  @invalid_erc20_contract "0x9080682a37961d3c814464e7ada1c7e1b4638a27"

  def invalid_erc20_contract_address, do: @invalid_erc20_contract

  def start_link(attrs), do: GenServer.start_link(__MODULE__, attrs, [])

  def init(%{
        hot_wallet_address: hot_wallet_address,
        deposit_wallet_address: deposit_wallet_address,
        erc20_address: erc20_address,
        other_address: other_address
      }) do
    {:ok,
     %{
       hot_wallet_address: hot_wallet_address,
       deposit_wallet_address: deposit_wallet_address,
       erc20_address: erc20_address,
       other_address: other_address
     }}
  end

  def stop(pid), do: GenServer.stop(pid)

  def handle_call(
        {:get_block, 0},
        _from,
        %{
          hot_wallet_address: hot_wallet_address,
          deposit_wallet_address: deposit_wallet_address,
          other_address: other_address
        } = state
      ) do
    {:reply,
     {:ok,
      %{
        "transactions" => [
          build_eth_transaction(0, "01", hot_wallet_address, other_address, 1_000),
          build_eth_transaction(0, "02", hot_wallet_address, other_address, 1_000),
          build_eth_transaction(0, "03", hot_wallet_address, other_address, 1_000),
          build_eth_transaction(0, "04", other_address, deposit_wallet_address, 1_000),
          build_eth_transaction(0, "05", other_address, Crypto.fake_eth_address(), 1_000)
        ]
      }}, state}
  end

  def handle_call(
        {:get_block, 1},
        _from,
        %{
          hot_wallet_address: hot_wallet_address,
          deposit_wallet_address: deposit_wallet_address,
          erc20_address: erc20_address,
          other_address: other_address
        } = state
      ) do
    {:reply,
     {:ok,
      %{
        "transactions" => [
          build_eth_transaction(1, "11", other_address, deposit_wallet_address, 1_337_000),
          build_erc20_transaction(
            1,
            "12",
            erc20_address,
            hot_wallet_address,
            other_address,
            1_000
          ),
          build_erc20_transaction(
            1,
            "13",
            erc20_address,
            other_address,
            deposit_wallet_address,
            1_000
          ),
          build_erc20_transaction(1, "14", erc20_address, other_address, other_address, 1_000)
        ]
      }}, state}
  end

  def handle_call(
        {:get_block, 2},
        _from,
        %{
          deposit_wallet_address: deposit_wallet_address,
          erc20_address: erc20_address,
          other_address: other_address
        } = state
      ) do
    {:reply,
     {:ok,
      %{
        "transactions" => [
          build_eth_transaction(2, "21", other_address, deposit_wallet_address, 1_000),
          build_erc20_transaction(
            2,
            "22",
            erc20_address,
            other_address,
            deposit_wallet_address,
            25_000
          )
        ]
      }}, state}
  end

  def handle_call({:get_block, n}, _from, state) when n < 5 do
    {:reply, {:ok, %{"transactions" => []}}, state}
  end

  def handle_call({:get_block, _}, _from, state) do
    {:reply, {:ok, nil}, state}
  end

  defp build_eth_transaction(blk_number, hash, from, to, value) do
    %{
      "blockNumber" => to_hex(blk_number),
      "blockHash" => "0xead7d63c2e78b7a35ff9d9b7b75c1945c1a7cce657fdcf01ea4c75dbcc915f62",
      "from" => from,
      "to" => to,
      "value" => to_hex(value),
      "gas" => to_hex(1),
      "gasPrice" => to_hex(1),
      "hash" => hash,
      "transactionIndex" => to_hex(0),
      "nonce" => to_hex(0),
      "input" => nil
    }
  end

  defp build_erc20_transaction(blk_number, hash, erc20_address, from, to, value) do
    {:ok, encoded_abi_data} = ABIEncoder.transfer(to, value)

    %{
      "blockNumber" => to_hex(blk_number),
      "blockHash" => "0xead7d63c2e78b7a35ff9d9b7b75c1945c1a7cce657fdcf01ea4c75dbcc915f62",
      "from" => from,
      "to" => erc20_address,
      "value" => to_hex(value),
      "gas" => to_hex(1),
      "gasPrice" => to_hex(1),
      "hash" => hash,
      "transactionIndex" => to_hex(0),
      "nonce" => to_hex(0),
      "input" => to_hex(encoded_abi_data)
    }
  end
end
