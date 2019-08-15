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

defmodule EWalletDB.BlockchainDepositWalletTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.BlockchainDepositWallet

  describe "all/1" do
    test "returns the list of all blockchain deposit wallets" do
      deposit_wallet_1 = insert(:blockchain_deposit_wallet)
      deposit_wallet_2 = insert(:blockchain_deposit_wallet)
      deposit_wallets = BlockchainDepositWallet.all("dumb")

      assert is_list(deposit_wallets)
      assert Enum.any?(deposit_wallets, fn w -> w.address == deposit_wallet_1.address end)
      assert Enum.any?(deposit_wallets, fn w -> w.address == deposit_wallet_2.address end)
    end
  end

  describe "get/2" do
    test "returns the blockchain deposit wallet by the given address" do
      deposit_wallet_1 = insert(:blockchain_deposit_wallet)
      deposit_wallet_2 = insert(:blockchain_deposit_wallet)

      assert BlockchainDepositWallet.get(deposit_wallet_1.address).uuid == deposit_wallet_1.uuid
      assert BlockchainDepositWallet.get(deposit_wallet_2.address).uuid == deposit_wallet_2.uuid
    end
  end

  describe "get_last_for/1" do
    test "returns the latest-generated blockchain deposit wallet for the given wallet" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      # The last wallet is the 3rd, but the last for wallet_1 should be the 2nd.
      _ = insert(:blockchain_deposit_wallet, wallet_address: wallet_1.address)
      w = insert(:blockchain_deposit_wallet, wallet_address: wallet_1.address)
      _ = insert(:blockchain_deposit_wallet, wallet_address: wallet_2.address)

      assert BlockchainDepositWallet.get_last_for(wallet_1).uuid == w.uuid
    end
  end

  describe "get_by/2" do
    test "returns the blockchain deposit wallet by the given fields" do
      deposit_wallet_1 = insert(:blockchain_deposit_wallet)
      deposit_wallet_2 = insert(:blockchain_deposit_wallet)
      deposit_wallet_3 = insert(:blockchain_deposit_wallet)

      assert BlockchainDepositWallet.get_by(uuid: deposit_wallet_1.uuid).uuid == deposit_wallet_1.uuid
      assert BlockchainDepositWallet.get_by(address: deposit_wallet_2.address).uuid == deposit_wallet_2.uuid
      assert BlockchainDepositWallet.get_by(public_key: deposit_wallet_3.public_key).uuid == deposit_wallet_3.uuid
    end
  end

  describe "insert/1" do
    test "returns the blockchain deposit wallet inserted with the given attributes" do
      attrs = params_for(:blockchain_deposit_wallet)
      {res, wallet} = BlockchainDepositWallet.insert(attrs)

      assert res == :ok
      assert %BlockchainDepositWallet{} = wallet
      assert attrs.address == wallet.address
    end
  end
end
