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

defmodule EWallet.BlockchainAddressFetcher do
  @moduledoc """
  Handles the retrieval and formatting of addresses for the blockchain
  """

  alias EWalletDB.{BlockchainDepositWallet, BlockchainWallet, Token}
  alias EWalletDB.Helpers.Preloader

  def get_all_trackable_wallet_addresses(blockchain_identifier) do
    hot_addresses = get_all_hot_wallet_addresses(blockchain_identifier)
    deposit_addresses = get_all_deposit_wallet_addresses(blockchain_identifier)

    Map.merge(hot_addresses, deposit_addresses)
  end

  def get_all_trackable_contract_address(blockchain_identifier) do
    blockchain_identifier
    |> Token.all_blockchain()
    |> Enum.map(fn token -> token.blockchain_address end)
  end

  defp get_all_hot_wallet_addresses(blockchain_identifier) do
    blockchain_identifier
    |> BlockchainWallet.get_all_hot()
    |> Enum.into(%{}, fn wallet -> {wallet.address, nil} end)
  end

  # TODO: Refactor to a more specific DB select for efficiency
  defp get_all_deposit_wallet_addresses(blockchain_identifier) do
    blockchain_identifier
    |> BlockchainDepositWallet.all()
    |> Preloader.preload(:wallet)
    |> Enum.into(%{}, fn deposit_wallet ->
      {deposit_wallet.address, deposit_wallet.wallet.address}
    end)
  end
end
