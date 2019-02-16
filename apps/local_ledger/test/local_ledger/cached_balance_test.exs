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

defmodule LocalLedger.CachedBalanceTest do
  use ExUnit.Case, async: true
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedger.{CachedBalance}
  alias LocalLedgerDB.{Repo}
  alias EWalletConfig.{Config, ConfigTestHelper}
  alias ActivityLogger.System

  setup do
    :ok = Sandbox.checkout(Repo)
    :ok = Sandbox.checkout(EWalletConfig.Repo)
    :ok = Sandbox.checkout(ActivityLogger.Repo)

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:local_ledger],
      %{}
    )

    token_1 = insert(:token, id: "tok_OMG_1234")
    token_2 = insert(:token, id: "tok_BTC_5678")
    wallet = insert(:wallet)

    # Total: +120_000 OMG
    insert_list(
      12,
      :credit,
      token: token_1,
      wallet: wallet,
      amount: 10_000
    )

    # Total: -61_047 OMG
    insert_list(
      9,
      :debit,
      token: token_1,
      wallet: wallet,
      amount: 6_783
    )

    # Total: +160_524 BTC
    insert_list(
      12,
      :credit,
      token: token_2,
      wallet: wallet,
      amount: 13_377
    )

    # Total: -74_961 BTC
    insert_list(
      9,
      :debit,
      token: token_2,
      wallet: wallet,
      amount: 8_329
    )

    %{token_1: token_1, token_2: token_2, wallet: wallet, config_pid: config_pid}
  end

  describe "cache_all/0" do
    test "caches all the wallets", %{token_1: token_1, wallet: wallet_1} do
      wallet_2 = insert(:wallet, address: "1232")

      # Total: +39_924 OMG
      insert_list(
        12,
        :credit,
        token: token_1,
        wallet: wallet_2,
        amount: 3_327
      )

      # Total: -35_028 OMG
      insert_list(
        9,
        :debit,
        token: token_1,
        wallet: wallet_2,
        amount: 3_892
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 2

      assert LocalLedgerDB.CachedBalance.get(wallet_1.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      assert LocalLedgerDB.CachedBalance.get(wallet_2.address).amounts == %{
               "tok_OMG_1234" => 39_924 - 35_028
             }
    end

    test "reuses the previous cached balance to calculate the new one when
          strategy = 'since_last_cached'",
         %{token_1: token_1, wallet: wallet, config_pid: config_pid} do
      Config.update(
        %{
          balance_caching_strategy: "since_last_cached",
          balance_caching_reset_frequency: 0,
          originator: %System{}
        },
        config_pid
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      # Then we manually add one to hijack the process - this value should be used to
      # calculate the next cached balance (even if it's incorrect in that case...)
      LocalLedgerDB.CachedBalance.insert(%{
        amounts: %{"tok_OMG_1234" => 3_000},
        wallet_address: wallet.address,
        cached_count: 1,
        computed_at: NaiveDateTime.utc_now()
      })

      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 2

      # Total: +1_000 OMG
      insert_list(
        2,
        :credit,
        token: token_1,
        wallet: wallet,
        amount: 500
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 3

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_OMG_1234" => 3_000 + 1_000
             }
    end

    test "increase the cached_count when calculating with strategy = 'since_last_cached'", %{
      wallet: wallet,
      config_pid: config_pid
    } do
      Config.update(
        %{
          balance_caching_strategy: "since_last_cached",
          balance_caching_reset_frequency: 0,
          originator: %System{}
        },
        config_pid
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 1
      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 2
    end

    test "Ignore the reset frequency when set to `nil` with strategy = 'since_last_cached'", %{
      wallet: wallet,
      config_pid: config_pid
    } do
      Config.update(
        %{
          balance_caching_strategy: "since_last_cached",
          balance_caching_reset_frequency: nil,
          originator: %System{}
        },
        config_pid
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 1
      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 2
    end

    test "cached_count is 1 when calculating with strategy = 'since_beginning'", %{wallet: wallet} do
      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 1
      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 1
    end

    test "cached_count is reset to 1 when reaching the reset frequency with strategy = 'since_last_cached'",
         %{wallet: wallet, config_pid: config_pid} do
      Config.update(
        %{
          balance_caching_strategy: "since_last_cached",
          balance_caching_reset_frequency: 3,
          originator: %System{}
        },
        config_pid
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 1
      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 2
      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance.get(wallet.address).cached_count == 1
    end

    test "Recalculate from beginning when reaching the reset frequency with strategy = 'since_last_cached'",
         %{token_1: token_1, wallet: wallet, config_pid: config_pid} do
      Config.update(
        %{
          balance_caching_strategy: "since_last_cached",
          balance_caching_reset_frequency: 3,
          originator: %System{}
        },
        config_pid
      )

      CachedBalance.cache_all()

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_BTC_5678" => 85_563,
               "tok_OMG_1234" => 58_953
             }

      # Manually insert a wrong amount
      LocalLedgerDB.CachedBalance.insert(%{
        amounts: %{"tok_BTC_5678" => 1_000, "tok_OMG_1234" => 3_000},
        wallet_address: wallet.address,
        cached_count: 1,
        computed_at: NaiveDateTime.utc_now()
      })

      insert(
        :credit,
        token: token_1,
        wallet: wallet,
        amount: 1000
      )

      CachedBalance.cache_all()

      # This is wrong because it's based on a wrongly calculated previous cached_balance
      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_BTC_5678" => 1_000,
               "tok_OMG_1234" => 4_000
             }

      # The reset_frequency is 3 so it will now calculate since the beginning
      # and sync the correct value
      CachedBalance.cache_all()

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_BTC_5678" => 85_563,
               "tok_OMG_1234" => 59_953
             }
    end

    test "reuses the previous cached balance to calculate the new one when
          strategy = 'since_beginning'",
         %{token_1: token_1, wallet: wallet} do
      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      # Then we manually add one to hijack the process - this value should NOT be used.
      LocalLedgerDB.CachedBalance.insert(%{
        amounts: %{"tok_OMG_1234" => 3_000},
        wallet_address: wallet.address,
        cached_count: 1,
        computed_at: NaiveDateTime.utc_now()
      })

      # Total: +1_000 OMG
      insert_list(
        2,
        :credit,
        token: token_1,
        wallet: wallet,
        amount: 500
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 3

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_OMG_1234" => 58_953 + 1_000,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end

    test "reuses the previous cached balance to calculate the new one if no strategy is given", %{
      token_1: token_1,
      wallet: wallet,
      config_pid: config_pid
    } do
      Config.update(
        %{
          balance_caching_strategy: nil,
          originator: %System{}
        },
        config_pid
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      # Then we manually add one to hijack the process - this value should NOT be used.
      LocalLedgerDB.CachedBalance.insert(%{
        amounts: %{"tok_OMG_1234" => 3_000},
        wallet_address: wallet.address,
        cached_count: 1,
        computed_at: NaiveDateTime.utc_now()
      })

      # Total: +1_000 OMG
      insert_list(
        2,
        :credit,
        token: token_1,
        wallet: wallet,
        amount: 500
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 3

      assert LocalLedgerDB.CachedBalance.get(wallet.address).amounts == %{
               "tok_OMG_1234" => 58_953 + 1_000,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end

    test "does not store a cached balance if all the amounts are equal to 0" do
      insert(:wallet, address: "1234")

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1
    end
  end

  describe "all/1" do
    test "calculates the balance and inserts a new cached balance if not existing", %{
      wallet: wallet
    } do
      {res, balances} = CachedBalance.all(wallet)
      assert res == :ok

      assert balances == %{
               wallet.address => %{
                 "tok_BTC_5678" => 160_524 - 74_961,
                 "tok_OMG_1234" => 120_000 - 61_047
               }
             }

      cached_balance = LocalLedgerDB.CachedBalance.get(wallet.address)
      assert cached_balance != nil

      assert balances == %{
               wallet.address => %{
                 "tok_BTC_5678" => 160_524 - 74_961,
                 "tok_OMG_1234" => 120_000 - 61_047
               }
             }

      assert cached_balance.amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end

    test "uses the cached balance and adds the entries that happened after", %{
      token_1: token_1,
      token_2: token_2,
      wallet: wallet
    } do
      {:ok, _balances} = CachedBalance.all(wallet)

      insert_list(1, :credit, token: token_1, wallet: wallet, amount: 1_337)
      insert_list(1, :debit, token: token_1, wallet: wallet, amount: 789)
      insert_list(1, :credit, token: token_2, wallet: wallet, amount: 1_232)
      insert_list(1, :debit, token: token_2, wallet: wallet, amount: 234)

      {:ok, balances} = CachedBalance.all(wallet)

      cached_count = LocalLedgerDB.CachedBalance |> Repo.all() |> length()
      cached_balance = LocalLedgerDB.CachedBalance.get(wallet.address)

      assert cached_count == 1

      assert cached_balance.amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      assert balances == %{
               wallet.address => %{
                 "tok_OMG_1234" => 58_953 + 1_337 - 789,
                 "tok_BTC_5678" => 160_524 - 74_961 + 1_232 - 234
               }
             }
    end

    test "calculates the balances for multiple address", %{token_1: token_1, wallet: wallet} do
      wallet_2 = insert(:wallet)

      # Total: +120_000 OMG
      insert_list(
        12,
        :credit,
        token: token_1,
        wallet: wallet_2,
        amount: 10_000
      )

      # Total: -61_047 OMG
      insert_list(
        9,
        :debit,
        token: token_1,
        wallet: wallet_2,
        amount: 6_783
      )

      {res, balances} = CachedBalance.all([wallet, wallet_2])

      assert res == :ok

      assert balances == %{
               wallet.address => %{
                 "tok_BTC_5678" => 160_524 - 74_961,
                 "tok_OMG_1234" => 120_000 - 61_047
               },
               wallet_2.address => %{"tok_OMG_1234" => 120_000 - 61_047}
             }

      {res, balances} = CachedBalance.all([wallet, wallet_2])

      assert res == :ok

      assert balances == %{
               wallet.address => %{
                 "tok_BTC_5678" => 160_524 - 74_961,
                 "tok_OMG_1234" => 120_000 - 61_047
               },
               wallet_2.address => %{"tok_OMG_1234" => 120_000 - 61_047}
             }
    end
  end

  describe "get/2" do
    test "calculates the balances for the given wallets", %{
      wallet: wallet
    } do
      wallet_2 = insert(:wallet)

      {res, wallets} = CachedBalance.get([wallet, wallet_2], "tok_OMG_1234")
      assert res == :ok

      assert wallets == %{
               wallet.address => %{"tok_OMG_1234" => 120_000 - 61_047},
               wallet_2.address => %{"tok_OMG_1234" => 0}
             }

      cached_balance = LocalLedgerDB.CachedBalance.get(wallet.address)
      assert cached_balance != nil

      assert cached_balance.amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      cached_balance = LocalLedgerDB.CachedBalance.get(wallet_2.address)
      assert cached_balance == nil
    end

    test "calculates the balance and inserts a new cached balance if not existing", %{
      wallet: wallet
    } do
      {res, amounts} = CachedBalance.get(wallet, "tok_OMG_1234")
      assert res == :ok
      assert amounts == %{wallet.address => %{"tok_OMG_1234" => 120_000 - 61_047}}

      cached_balance = LocalLedgerDB.CachedBalance.get(wallet.address)
      assert cached_balance != nil

      assert cached_balance.amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end
  end
end
