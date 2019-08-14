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

defmodule EWallet.BlockchainWalletGate do
  @moduledoc """
  Handle logic related to blockchain wallets
  """
  alias EWallet.{AddressTracker, BlockchainHelper}
  alias EWalletDB.{BlockchainDepositWallet, BlockchainHDWallet, Token}
  alias Keychain.Wallet

  def deposit_to_childchain(
        wallet,
        %{
          "amount" => amount,
          "currency" => currency,
          "address" => address
        } = attrs
      )
      when is_integer(amount) do
    with :ok <- BlockchainHelper.validate_blockchain_address(currency),
         # TODO: Also check for status
         %Token{} = token <-
           Token.get_by(
             blockchain_identifier: BlockchainHelper.identifier(),
             blockchain_address: currency
           ) || {:error, :unauthorized},
         {:ok, tx_hash} <-
           BlockchainHelper.call(:deposit_to_childchain, %{
             childchain_identifier: attrs["childchain_identifier"],
             amount: amount,
             currency: token.blockchain_address,
             to: address
           }) do
      {:ok, tx_hash}
      # TODO: track deposit transaction with transaction tracker
    else
      error ->
        error
    end
  end

  def deposit_to_childchain(wallet, _) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount` and `currency` are required."}
  end
end
