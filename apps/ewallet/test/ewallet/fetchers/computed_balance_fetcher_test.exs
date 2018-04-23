defmodule EWallet.ComputedBalanceFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.ComputedBalanceFetcher
  alias EWalletDB.{User, MintedToken, Account}
  alias Ecto.Adapters.SQL.Sandbox

  describe "all/1" do
    test "retrieve all balances from a provider_user_id" do
      account = Account.get_master_account()
      master_balance = Account.get_primary_balance(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_balance = User.get_primary_balance(user)
      {:ok, btc} = :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()
      {:ok, omg} = :minted_token |> params_for(symbol: "OMG") |> MintedToken.insert()
      {:ok, knc} = :minted_token |> params_for(symbol: "KNC") |> MintedToken.insert()

      mint!(btc)
      mint!(omg)
      mint!(knc)

      transfer!(master_balance.address, user_balance.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_balance.address, user_balance.address, omg, 12_000 * omg.subunit_to_unit)

      {status, address} =
        ComputedBalanceFetcher.all(%{"provider_user_id" => user.provider_user_id})

      assert status == :ok
      assert address.address == User.get_primary_balance(user).address

      assert address.balances == [
               %{minted_token: btc, amount: 150_000 * btc.subunit_to_unit},
               %{minted_token: omg, amount: 12_000 * omg.subunit_to_unit},
               %{minted_token: knc, amount: 0}
             ]
    end
  end

  describe "get/2" do
    test "retrieve the specific balance from a minted_token and an address" do
      account = Account.get_master_account()
      master_balance = Account.get_primary_balance(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_balance = User.get_primary_balance(user)
      {:ok, omg} = :minted_token |> params_for(symbol: "OMG") |> MintedToken.insert()
      {:ok, btc} = :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()
      {:ok, knc} = :minted_token |> params_for(symbol: "KNC") |> MintedToken.insert()

      mint!(btc)
      mint!(omg)
      mint!(knc)

      transfer!(master_balance.address, user_balance.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_balance.address, user_balance.address, omg, 12_000 * omg.subunit_to_unit)

      {status, address} = ComputedBalanceFetcher.get(omg.id, user_balance.address)
      assert status == :ok
      assert address.address == User.get_primary_balance(user).address

      assert address.balances == [
               %{minted_token: omg, amount: 12_000 * omg.subunit_to_unit}
             ]
    end
  end
end
