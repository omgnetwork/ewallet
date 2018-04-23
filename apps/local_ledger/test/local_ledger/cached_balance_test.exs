defmodule LocalLedger.CachedBalanceTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedger.{CachedBalance}
  alias LocalLedgerDB.{Repo}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)

    minted_token_1 = insert(:minted_token, id: "tok_OMG_1234")
    minted_token_2 = insert(:minted_token, id: "tok_BTC_5678")
    balance = insert(:balance)

    # Total: +120_000 OMG
    insert_list(
      12,
      :credit,
      minted_token: minted_token_1,
      balance: balance,
      amount: 10_000
    )

    # Total: -61_047 OMG
    insert_list(
      9,
      :debit,
      minted_token: minted_token_1,
      balance: balance,
      amount: 6_783
    )

    # Total: +160_524 BTC
    insert_list(
      12,
      :credit,
      minted_token: minted_token_2,
      balance: balance,
      amount: 13_377
    )

    # Total: -74_961 BTC
    insert_list(
      9,
      :debit,
      minted_token: minted_token_2,
      balance: balance,
      amount: 8_329
    )

    %{minted_token_1: minted_token_1, minted_token_2: minted_token_2, balance: balance}
  end

  describe "cache_all/0" do
    test "caches all the balances", %{minted_token_1: minted_token_1, balance: balance_1} do
      balance_2 = insert(:balance, address: "1232")

      # Total: +39_924 OMG
      insert_list(
        12,
        :credit,
        minted_token: minted_token_1,
        balance: balance_2,
        amount: 3_327
      )

      # Total: -35_028 OMG
      insert_list(
        9,
        :debit,
        minted_token: minted_token_1,
        balance: balance_2,
        amount: 3_892
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 2

      assert LocalLedgerDB.CachedBalance.get(balance_1.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      assert LocalLedgerDB.CachedBalance.get(balance_2.address).amounts == %{
               "tok_OMG_1234" => 39_924 - 35_028
             }
    end

    test "reuses the previous cached balance to calculate the new one when
          strategy = 'since_last_cached'", %{minted_token_1: minted_token_1, balance: balance} do
      Application.put_env(:local_ledger, :balance_caching_strategy, "since_last_cached")

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1

      assert LocalLedgerDB.CachedBalance.get(balance.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      # Then we manually add one to hijack the process - this value should be used to
      # calculate the next cached balance (even if it's incorrect in that case...)
      LocalLedgerDB.CachedBalance.insert(%{
        amounts: %{"tok_OMG_1234" => 3_000},
        balance_address: balance.address,
        computed_at: NaiveDateTime.utc_now()
      })

      # Total: +1_000 OMG
      insert_list(
        2,
        :credit,
        minted_token: minted_token_1,
        balance: balance,
        amount: 500
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 3

      assert LocalLedgerDB.CachedBalance.get(balance.address).amounts == %{
               "tok_OMG_1234" => 3_000 + 1_000
             }
    end

    test "reuses the previous cached balance to calculate the new one when
          strategy = 'since_beginning'", %{minted_token_1: minted_token_1, balance: balance} do
      Application.put_env(:local_ledger, :balance_caching_strategy, "since_beginning")

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1

      assert LocalLedgerDB.CachedBalance.get(balance.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      # Then we manually add one to hijack the process - this value should NOT be used.
      LocalLedgerDB.CachedBalance.insert(%{
        amounts: %{"tok_OMG_1234" => 3_000},
        balance_address: balance.address,
        computed_at: NaiveDateTime.utc_now()
      })

      # Total: +1_000 OMG
      insert_list(
        2,
        :credit,
        minted_token: minted_token_1,
        balance: balance,
        amount: 500
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 3

      assert LocalLedgerDB.CachedBalance.get(balance.address).amounts == %{
               "tok_OMG_1234" => 58_953 + 1_000,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end

    test "reuses the previous cached balance to calculate the new one if no strategy is given", %{
      minted_token_1: minted_token_1,
      balance: balance
    } do
      Application.put_env(:local_ledger, :balance_caching_strategy, nil)

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1

      assert LocalLedgerDB.CachedBalance.get(balance.address).amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      # Then we manually add one to hijack the process - this value should NOT be used.
      LocalLedgerDB.CachedBalance.insert(%{
        amounts: %{"tok_OMG_1234" => 3_000},
        balance_address: balance.address,
        computed_at: NaiveDateTime.utc_now()
      })

      # Total: +1_000 OMG
      insert_list(
        2,
        :credit,
        minted_token: minted_token_1,
        balance: balance,
        amount: 500
      )

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 3

      assert LocalLedgerDB.CachedBalance.get(balance.address).amounts == %{
               "tok_OMG_1234" => 58_953 + 1_000,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end

    test "does not store a cached balance if all the amounts are equal to 0" do
      insert(:balance, address: "1234")

      CachedBalance.cache_all()
      assert LocalLedgerDB.CachedBalance |> Repo.all() |> length() == 1
    end
  end

  describe "all/1" do
    test "calculates the balance and inserts a new cached balance if not existing", %{
      balance: balance
    } do
      {res, amounts} = CachedBalance.all(balance)
      assert res == :ok

      assert amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      cached_balance = LocalLedgerDB.CachedBalance.get(balance.address)
      assert cached_balance != nil

      assert cached_balance.amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end

    test "uses the cached balance and adds the transactions that happened after", %{
      minted_token_1: minted_token_1,
      minted_token_2: minted_token_2,
      balance: balance
    } do
      {:ok, _amounts} = CachedBalance.all(balance)

      insert_list(1, :credit, minted_token: minted_token_1, balance: balance, amount: 1_337)
      insert_list(1, :debit, minted_token: minted_token_1, balance: balance, amount: 789)
      insert_list(1, :credit, minted_token: minted_token_2, balance: balance, amount: 1_232)
      insert_list(1, :debit, minted_token: minted_token_2, balance: balance, amount: 234)

      {:ok, amounts} = CachedBalance.all(balance)

      cached_count = LocalLedgerDB.CachedBalance |> Repo.all() |> length()
      cached_balance = LocalLedgerDB.CachedBalance.get(balance.address)

      assert cached_count == 1

      assert cached_balance.amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }

      assert amounts == %{
               "tok_OMG_1234" => 58_953 + 1_337 - 789,
               "tok_BTC_5678" => 160_524 - 74_961 + 1_232 - 234
             }
    end
  end

  describe "get/2" do
    test "calculates the balance and inserts a new cached balance if not existing", %{
      balance: balance
    } do
      {res, amounts} = CachedBalance.get(balance, "tok_OMG_1234")
      assert res == :ok
      assert amounts == %{"tok_OMG_1234" => 120_000 - 61_047}

      cached_balance = LocalLedgerDB.CachedBalance.get(balance.address)
      assert cached_balance != nil

      assert cached_balance.amounts == %{
               "tok_OMG_1234" => 120_000 - 61_047,
               "tok_BTC_5678" => 160_524 - 74_961
             }
    end
  end
end
