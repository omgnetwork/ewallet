defmodule LocalLedger.CachedBalanceTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedger.{CachedBalance}
  alias LocalLedgerDB.{Repo}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)

    minted_token_1 = insert(:minted_token, friendly_id: "OMG:1234")
    minted_token_2 = insert(:minted_token, friendly_id: "BTC:1234")
    balance        = insert(:balance)

    insert_list(12, :credit, minted_token: minted_token_1,
                             balance: balance,
                             amount: 10_000)
    insert_list(9, :debit, minted_token: minted_token_1,
                           balance: balance,
                           amount: 6_783)

    insert_list(12, :credit, minted_token: minted_token_2,
                             balance: balance,
                             amount: 13_377)
    insert_list(9, :debit, minted_token: minted_token_2,
                           balance: balance,
                           amount: 8_329)

    %{minted_token_1: minted_token_1, minted_token_2: minted_token_2, balance: balance}
  end

  describe "#all" do
    test "calculates the balance and inserts a new cached balance if not existing",
      %{minted_token_1: minted_token_1, minted_token_2: minted_token_2, balance: balance}
    do
      {res, amounts} = CachedBalance.all(balance)
      assert res == :ok
      assert amounts == %{
        minted_token_1.friendly_id => 58_953,
        minted_token_2.friendly_id => 85_563
      }

      cached_balance = LocalLedgerDB.CachedBalance.get(balance.address)
      assert cached_balance != nil
      assert cached_balance.amounts == %{
        minted_token_1.friendly_id => 58_953,
        minted_token_2.friendly_id => 85_563
      }
    end

    test "uses the cached balance and adds the transactions that happened after",
      %{minted_token_1: minted_token_1, minted_token_2: minted_token_2, balance: balance}
    do
      {:ok, _amounts} = CachedBalance.all(balance)

      insert_list(1, :credit, minted_token: minted_token_1, balance: balance, amount: 1_337)
      insert_list(1, :debit, minted_token: minted_token_1, balance: balance, amount: 789)
      insert_list(1, :credit, minted_token: minted_token_2, balance: balance, amount: 1_232)
      insert_list(1, :debit, minted_token: minted_token_2, balance: balance, amount: 234)

      {:ok, amounts} = CachedBalance.all(balance)

      cached_count   = LocalLedgerDB.CachedBalance |> Repo.all() |> length()
      cached_balance = LocalLedgerDB.CachedBalance.get(balance.address)

      assert cached_count == 1
      assert cached_balance.amounts == %{
        minted_token_1.friendly_id => 58_953,
        minted_token_2.friendly_id => 85_563
      }

      assert amounts == %{
        minted_token_1.friendly_id => 58_953 + 1_337 - 789,
        minted_token_2.friendly_id => 85_563 + 1_232 - 234
      }
    end
  end

  describe "#get" do
    test "calculates the balance and inserts a new cached balance if not existing",
      %{minted_token_1: minted_token_1, minted_token_2: minted_token_2, balance: balance}
    do
      {res, amounts} = CachedBalance.get(balance, minted_token_1.friendly_id)
      assert res == :ok
      assert amounts == %{minted_token_1.friendly_id => 58_953}

      cached_balance = LocalLedgerDB.CachedBalance.get(balance.address)
      assert cached_balance != nil
      assert cached_balance.amounts == %{
        minted_token_1.friendly_id => 58_953,
        minted_token_2.friendly_id => 85_563
      }
    end

    test "uses the cached balance and adds the transactions that happened after",
      %{minted_token_1: minted_token_1, minted_token_2: minted_token_2, balance: balance}
    do
      {:ok, _amounts} = CachedBalance.get(balance, minted_token_1.friendly_id)

      insert_list(1, :credit, minted_token: minted_token_1, balance: balance, amount: 1_337)
      insert_list(1, :debit, minted_token: minted_token_1, balance: balance, amount: 789)

      {:ok, amounts} = CachedBalance.get(balance, minted_token_1.friendly_id)

      cached_count   = LocalLedgerDB.CachedBalance |> Repo.all() |> length()
      cached_balance = LocalLedgerDB.CachedBalance.get(balance.address)

      assert cached_count == 1
      assert cached_balance.amounts == %{
        minted_token_1.friendly_id => 58_953,
        minted_token_2.friendly_id => 85_563
      }
      assert amounts == %{minted_token_1.friendly_id => 58_953 + 1_337 - 789}
    end
  end
end
