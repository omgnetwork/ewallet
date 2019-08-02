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

  # All the actual interactions with the childchain in the functions below should be extracted
  # to another subapp: EthElixirOMGAdapter

  def deposit(%{childchain_identifier: childchain_identifier, address: address} = attrs, adapter \\ nil, pid \\ nil) do
    # check that childchain identifier is supported
    childchains = Application.get_env(:eth_blockchain, :childchains)

    case childchainds[childchain_identifier] do
      nil ->
        {:error, :childchain_not_supported}
      config ->
        config[:contract_address]
        # TODO: deposit to rootchain
        # TODO: handle both ETH & ERC-20
        # https://github.com/omisego/plasma-contracts/blob/master/contracts/RootChain.sol
        # TODO: return transaction hash
    end
  end

  def send() do

  def get_block() do
    # TODO: get block and parse transactions to find relevant ones
    # to be used by a childchain AddressTracker
  end

  def get_exitable_utxos() do
    # TODO: Check if childchain is supported
    # TODO: Retrieve exitable utxos from Watcher API
  end

  def exit(%{childchain_identifier: childchain_identifier, address: address, utxos: utxos} = attrs, adapter \\ nil, pid \\ nil) do
    # TODO: 1. Check if childchain is supported
    # TODO: 2. Attempt to exit all given utxos
  end
end
