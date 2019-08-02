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

  """
  alias EWallet.{AddressTracker, BlockchainHelper}
  alias EWalletDB.{BlockchainDepositWallet, BlockchainHDWallet}
  alias Keychain.Wallet

  def deposit(wallet, %{
    childchain_identifier: childchain_identifier,
    amount: amount,
    token_id: token_id,
  } = attrs) do
    with token = Token.get(token_id) do
      {:ok, transaction} = BlockchainHelper.call(:deposit_to_childchain, %{
        childchain_identifier: childchain_identifier,
        amount: amount,
        token_contract_address: token.blockchain_address
      })

      # track deposit transaction with transaction tracker
    else
      error ->
        error
    end
  end

  def deposit(wallet, _) do
    {:invalid_parameter, "Invalid parameter provided. `address` is required."}
  end
end
