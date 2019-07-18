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
  alias EWallet.AddressTracker
  alias EWalletDB.{BlockchainDepositWallet, BlockchainHDWallet}
  alias Keychain.Wallet

  def get_or_generate(wallet, %{"originator" => originator}) do
    case BlockchainDepositWallet.get_last_for(wallet) do
      nil ->
        case BlockchainHDWallet.get_primary() do
          nil ->
            {:error, :hd_wallet_not_found} # TODO: Handle error in ErrorHandler
          hd_wallet ->
            ref = generate_unique_ref()
            address = Wallet.generate_child_account(hd_wallet.keychain_uuid, ref, 0)

            %{
              address: address,
              path_ref: ref,
              wallet_address: wallet.address,
              blockchain_hd_wallet_uuid: hd_wallet.uuid,
              originator: originator,
            }
            |> BlockchainDepositWallet.insert()
            |> case do
              {:ok, deposit_wallet} ->
                :ok = AddressTracker.register_address(deposit_wallet.address, deposit_wallet.wallet_address)
                {:ok, Map.put(wallet, :deposit_wallet, deposit_wallet)}
              error ->
                error
            end
        end

      deposit_wallet ->
        {:ok, Map.put(wallet, :deposit_wallet, deposit_wallet)}
    end
  end

  defp generate_unique_ref do
    :rand.uniform(999_999_999)
  end
end
