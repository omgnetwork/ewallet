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
  alias EWallet.Web.{BlockchainBalanceLoader, Preloader}

  alias EWalletDB.{
    BlockchainDepositWallet,
    BlockchainDepositWalletCachedBalance,
    BlockchainHDWallet,
    Wallet
  }

  alias Keychain.Wallet, as: KeychainWallet

  @rootchain_identifier BlockchainHelper.rootchain_identifier()
  @burn_identifier Wallet.burn()
  @deposit_ref 0

  @doc """
  Gets an existing blockchain deposit wallet for the given `EWalletDB.Wallet`,
  creates a new one if it does not exist yet.

  This effectively allows only 1 blockchain deposit wallet per `EWalletDB.Wallet`.
  """
  def get_or_generate(%{identifier: @burn_identifier}, _) do
    {:error, :blockchain_deposit_wallet_for_burn_wallet_not_allowed}
  end

  def get_or_generate(wallet, %{"originator" => originator}) do
    case BlockchainDepositWallet.get_last_for(wallet) do
      nil ->
        do_generate(wallet, originator)

      deposit_wallet ->
        {:ok, deposit_wallet}
    end
  end

  defp do_generate(wallet, originator) do
    with %BlockchainHDWallet{} = hd_wallet <-
           BlockchainHDWallet.get_primary() || {:error, :hd_wallet_not_found},
         {:ok, wallet_ref} <- Wallet.get_or_generate_hd_path(wallet),
         {:ok, deposit_wallet} <-
           do_insert(wallet, hd_wallet, wallet_ref, @deposit_ref, originator),
         {:ok, deposit_wallet} <- Preloader.preload_one(deposit_wallet, :wallet) do
      :ok =
        AddressTracker.register_address(
          deposit_wallet.address,
          deposit_wallet.wallet.address
        )

      {:ok, deposit_wallet}
    else
      error ->
        error
    end
  end

  defp do_insert(wallet, hd_wallet, wallet_ref, deposit_ref, originator) do
    address =
      KeychainWallet.derive_child_address(hd_wallet.keychain_uuid, wallet_ref, deposit_ref)

    BlockchainDepositWallet.insert(%{
      wallet_uuid: wallet.uuid,
      blockchain_hd_wallet_uuid: hd_wallet.uuid,
      relative_hd_path: deposit_ref,
      address: address,
      blockchain_identifier: @rootchain_identifier,
      originator: originator
    })
  end

  @doc """
  Creates or updates the local copy of the blockchain balances
  for the given wallet address and tokens.
  """
  def refresh_balances(deposit_wallet, tokens) do
    tokens = List.wrap(tokens)

    {:ok, [deposit_wallet_with_balances]} =
      BlockchainBalanceLoader.wallet_balances(
        [deposit_wallet],
        tokens,
        deposit_wallet.blockchain_identifier
      )

    {:ok,
     BlockchainDepositWalletCachedBalance.create_or_update_all(
       deposit_wallet_with_balances.address,
       deposit_wallet_with_balances.balances,
       deposit_wallet.blockchain_identifier
     )}
  end
end
