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

defmodule EWallet.BlockchainAddressFetcherTest do
  use EWallet.DBCase, async: true
  alias EWallet.{BlockchainAddressFetcher, BlockchainHelper}
  alias EWalletDB.BlockchainWallet

  describe "get_all_trackable_wallet_addresses/1" do
    test "returns the list of all trackable wallet addresses" do
      identifier = BlockchainHelper.identifier()
      primary_hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)
      result = BlockchainAddressFetcher.get_all_trackable_wallet_addresses(identifier)

      assert result == %{primary_hot_wallet.address => nil}
    end
  end

  describe "get_all_trackable_contract_address/1" do
    test "returns the list of all trackable contract addresses" do
      identifier = BlockchainHelper.identifier()
      result = BlockchainAddressFetcher.get_all_trackable_contract_address(identifier)

      assert result == []
    end
  end
end
