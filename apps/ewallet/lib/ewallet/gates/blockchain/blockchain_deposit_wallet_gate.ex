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
  Handles the logic for generating and retrieving a blockchain deposit wallet.
  """
  alias EWallet.{AddressTracker, BlockchainHelper}
  alias EWalletDB.{BlockchainDepositWallet, BlockchainHDWallet}
  alias Keychain.Wallet

  @burn_identifier EWalletDB.Wallet.burn()

  def get_or_generate(%{identifier: @burn_identifier}, _) do
    {:error, :blockchain_deposit_wallet_for_burn_wallet_not_allowed}
  end

  def get_or_generate(wallet, %{"originator" => originator}) do
    case BlockchainDepositWallet.get_last_for(wallet) do
      nil ->
        do_generate(wallet, orginator)

      deposit_wallet ->
        {:ok, Map.put(wallet, :blockchain_deposit_wallets, [deposit_wallet])}
    end
  end

  defp do_generate(wallet, originator) do
    case BlockchainHDWallet.get_primary() do
      nil ->
        {:error, :hd_wallet_not_found}

      hd_wallet ->
        ref = generate_unique_ref()
        address = Wallet.derive_child_address(hd_wallet.keychain_uuid, ref, 0)

        %{
          address: address,
          path_ref: ref,
          wallet_address: wallet.address,
          blockchain_hd_wallet_uuid: hd_wallet.uuid,
          originator: originator,
          blockchain_identifier: BlockchainHelper.identifier()
        }
        |> BlockchainDepositWallet.insert()
        |> case do
          {:ok, deposit_wallet} ->
            :ok =
              AddressTracker.register_address(
                deposit_wallet.address,
                deposit_wallet.wallet_address
              )

            {:ok, Map.put(wallet, :blockchain_deposit_wallets, [deposit_wallet])}

          error ->
            error
        end
    end
  end

  # TODO: Handle the possibility of generating clashing numbers
  defp generate_unique_ref do
    :rand.uniform(999_999_999)
  end
end
