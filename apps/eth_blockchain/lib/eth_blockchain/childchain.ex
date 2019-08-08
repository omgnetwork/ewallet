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
  alias EthBlockchain.{Adapter, Helper}

  @eth EthBlockchain.Helper.default_address()

  # All the actual interactions with the childchain in the functions below should be extracted
  # to another subapp: EthElixirOMGAdapter

  def deposit(
        %{
          childchain_identifier: childchain_identifier,
          to: to,
          amount: amount,
          currency: currency_address
        },
        adapter \\ nil,
        pid \\ nil
      ) do
    # check that childchain identifier is supported
    childchains = Application.get_env(:eth_blockchain, :childchains)

    case childchains[childchain_identifier] do
      nil ->
        {:error, :childchain_not_supported}

      %{contract_address: contract_address} ->
        deposit_to_child_chain(to, amount, currency_address, contract_address, adapter, pid)
    end

    # TODO: deposit to rootchain
    # TODO: handle both ETH & ERC-20
    # https://github.com/omisego/plasma-contracts/blob/master/contracts/RootChain.sol
    # TODO: return transaction hash
  end

  def deposit_to_child_chain(to, amount, token \\ @eth, contract_address, adapter, pid)

  def deposit_to_child_chain(to, amount, @eth, contract_address, adapter, pid) do
    IO.inspect("depositing eth")

    tx_bytes =
      []
      |> EthBlockchain.Plasma.Transaction.new([
        {from_hex(to), from_hex(@eth), amount}
      ])
      |> EthBlockchain.Plasma.Transaction.raw_txbytes()

    IO.inspect("encoded tx_bytes")
    IO.inspect(tx_bytes, limit: :infinity)

    a =
      EthBlockchain.Transaction.deposit_eth(
        %{tx_bytes: tx_bytes, from: to, amount: amount, contract: contract_address},
        adapter,
        pid
      )

    # |> Eth.DevHelpers.transact_sync!()
    IO.inspect(a)

    # process_deposit(receipt)
  end

  # def deposit_to_child_chain(to, value, token_addr, contract_address, adapter, pid) do
  # TODO

  # contract_addr = Eth.Encoding.from_hex(Application.fetch_env!(:omg_eth, :contract_addr))

  # to |> Eth.Token.mint(value, token_addr) |> Eth.DevHelpers.transact_sync!()
  # to |> Eth.Token.approve(contract_addr, value, token_addr) |> Eth.DevHelpers.transact_sync!()

  # {:ok, receipt} =
  #   Transaction.new([], [{to, token_addr, value}])
  #   |> Transaction.encode()
  #   |> do_deposit_from(to)
  #   |> Eth.DevHelpers.transact_sync!()

  # process_deposit(receipt)
  # end

  def send() do
  end

  def get_block() do
    # TODO: get block and parse transactions to find relevant ones
    # to be used by a childchain AddressTracker
  end

  def get_exitable_utxos() do
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
