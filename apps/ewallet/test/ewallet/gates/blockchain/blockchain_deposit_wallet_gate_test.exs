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

defmodule EWallet.BlockchainDepositWalletGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWallet.BlockchainDepositWalletGate
  alias EWalletDB.Wallet, as: DBWallet
  alias EWalletDB.{BlockchainDepositWallet, BlockchainHDWallet, Repo}

  describe "get_or_generate/2" do
    test "generates a deposit wallet if it is not yet generated for the given wallet" do
      wallet = insert(:wallet) |> Repo.preload(:blockchain_deposit_wallets)
      assert wallet.blockchain_deposit_wallets == []

      {res, updated} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      assert res == :ok
      assert [%BlockchainDepositWallet{}] = updated.blockchain_deposit_wallets
    end

    test "generates a deposit wallet for a secondary wallet" do
      wallet =
        insert(:wallet, identifier: DBWallet.secondary())
        |> Repo.preload(:blockchain_deposit_wallets)

      assert wallet.blockchain_deposit_wallets == []

      {res, updated} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      assert res == :ok
      assert [%BlockchainDepositWallet{}] = updated.blockchain_deposit_wallets
    end

    test "returns the existing deposit wallet if it is already generated for the given wallet" do
      wallet = insert(:wallet)

      {:ok, original} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      {res, updated} =
        BlockchainDepositWalletGate.get_or_generate(original, %{"originator" => %System{}})

      updated = Repo.preload(updated, :blockchain_deposit_wallets)

      assert res == :ok
      assert length(updated.blockchain_deposit_wallets) == 1

      assert hd(updated.blockchain_deposit_wallets).uuid ==
               hd(original.blockchain_deposit_wallets).uuid
    end

    test "returns an error when generating a deposit wallet for a burn wallet" do
      wallet =
        insert(:wallet, identifier: DBWallet.burn()) |> Repo.preload(:blockchain_deposit_wallets)

      assert wallet.blockchain_deposit_wallets == []

      {res, error} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      assert res == :error
      assert error == :blockchain_deposit_wallet_for_burn_wallet_not_allowed
    end

    test "returns :hd_wallet_not_found error if the primary HD wallet is missing" do
      BlockchainHDWallet.get_primary() |> Repo.delete()
      wallet = insert(:wallet)
      _ = Repo.delete_all(BlockchainHDWallet)

      {res, error} =
        BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})

      assert res == :error
      assert error == :hd_wallet_not_found
    end
  end

  describe "refresh_balances/3" do
    test "updates the deposit wallet balances with the latest blockchain state" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      wallet = insert(:blockchain_deposit_wallet)

      _ =
        insert(:blockchain_deposit_wallet_balance,
          blockchain_deposit_wallet: wallet,
          amount: 10,
          token: token_1
        )

      _ =
        insert(:blockchain_deposit_wallet_balance,
          blockchain_deposit_wallet: wallet,
          amount: 20,
          token: token_2
        )

      wallet = BlockchainDepositWallet.reload_balances(wallet)

      assert Enum.any?(wallet.balances, fn b -> b.token_uuid == token_1.uuid && b.amount == 10 end)

      assert Enum.any?(wallet.balances, fn b -> b.token_uuid == token_2.uuid && b.amount == 20 end)

      # Assert two successful refreshes
      {res, data} =
        BlockchainDepositWalletGate.refresh_balances(wallet.address, "ethereum", [token_1, token_2])

      assert res == :ok
      assert [{:ok, _}, {:ok, _}] = data

      # The dumb adapter hard codes the amount to 123
      wallet = BlockchainDepositWallet.reload_balances(wallet)

      assert Enum.any?(wallet.balances, fn b ->
               b.token_uuid == token_1.uuid && b.amount == 123
             end)

      assert Enum.any?(wallet.balances, fn b ->
               b.token_uuid == token_2.uuid && b.amount == 123
             end)
    end
  end
end
