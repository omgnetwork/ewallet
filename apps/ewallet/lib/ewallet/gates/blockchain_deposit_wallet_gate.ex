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

defmodule EWallet.BlockchainDepositWalletGate do
  @moduledoc """

  """
  alias EWalletDB.{BlockchainDepositWallet, BlockchainHDWallet}
  alias Keychain.Wallet

  def get_or_generate(wallet) do
    case BlockchainDepositWallet.get_last_for(wallet) do
      nil ->
        case BlockchainHDWallet.get_primary() do
          nil ->
            {:error, :hd_wallet_not_found}
          hd_wallet ->
            ref = 1 # TODO: generate random int?
            address = Wallet.generate_child_account(hd_wallet.keychain_uuid, ref, 0)

            # TODO: Store refs with record
            BlockchainDepositWallet.insert(%{
              address: address,
              wallet_address: wallet.address
            })

            # TODO: Notify Address Tracker to track this address
        end

      deposit_wallet ->
        Map.put(wallet, :deposit_wallet, deposit_wallet)
    end
  end
end
