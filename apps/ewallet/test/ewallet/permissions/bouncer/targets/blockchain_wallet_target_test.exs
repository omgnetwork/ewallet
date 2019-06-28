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

defmodule EWallet.Bouncer.BlockchainWalletTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{BlockchainWalletTarget, DispatchConfig}

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the blockchain wallet" do
      wallet = insert(:blockchain_wallet)
      res = BlockchainWalletTarget.get_owner_uuids(wallet)
      assert res == []
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert BlockchainWalletTarget.get_target_types() == [:blockchain_wallets]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given blockchain wallet" do
      wallet = insert(:blockchain_wallet)
      assert BlockchainWalletTarget.get_target_type(wallet) == :blockchain_wallets
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the blockchain wallet" do
      wallet = insert(:blockchain_wallet)
      assert BlockchainWalletTarget.get_target_accounts(wallet, DispatchConfig) == []
    end
  end
end
