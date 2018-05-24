defmodule EWallet.BalanceFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.BalanceFetcher
  alias EWalletDB.{User, Token, Account}
  alias Ecto.Adapters.SQL.Sandbox

  describe "all/1" do
    test "retrieve all wallets from a provider_user_id" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()
      {:ok, omg} = :token |> params_for(symbol: "OMG") |> Token.insert()
      {:ok, knc} = :token |> params_for(symbol: "KNC") |> Token.insert()

      mint!(btc)
      mint!(omg)
      mint!(knc)

      transfer!(master_wallet.address, user_wallet.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_wallet.address, user_wallet.address, omg, 12_000 * omg.subunit_to_unit)

      {status, wallet} = BalanceFetcher.all(%{"provider_user_id" => user.provider_user_id})

      assert status == :ok
      assert wallet.address == User.get_primary_wallet(user).address

      assert wallet.balances == [
               %{token: btc, amount: 150_000 * btc.subunit_to_unit},
               %{token: omg, amount: 12_000 * omg.subunit_to_unit},
               %{token: knc, amount: 0}
             ]
    end
  end

  describe "get/2" do
    test "retrieve the specific wallet from a token and an address" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)
      {:ok, omg} = :token |> params_for(symbol: "OMG") |> Token.insert()
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()
      {:ok, knc} = :token |> params_for(symbol: "KNC") |> Token.insert()

      mint!(btc)
      mint!(omg)
      mint!(knc)

      transfer!(master_wallet.address, user_wallet.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_wallet.address, user_wallet.address, omg, 12_000 * omg.subunit_to_unit)

      {status, wallet} = BalanceFetcher.get(omg.id, user_wallet)
      assert status == :ok
      assert wallet.address == User.get_primary_wallet(user).address

      assert wallet.balances == [
               %{token: omg, amount: 12_000 * omg.subunit_to_unit}
             ]
    end
  end
end
