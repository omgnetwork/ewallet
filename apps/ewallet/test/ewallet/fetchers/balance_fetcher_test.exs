defmodule EWallet.BalanceFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias EWallet.BalanceFetcher
  alias EWalletDB.{Account, Token, User}

  setup do
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

    %{
      master_wallet: master_wallet,
      user_wallet: user_wallet,
      user: user,
      btc: btc,
      omg: omg,
      knc: knc
    }
  end

  describe "all/1" do
    test "retrieve all wallets from a user_id", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        990_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        57_000 * context.omg.subunit_to_unit
      )

      {status, wallet} = BalanceFetcher.all(%{"user_id" => context.user.id})

      assert status == :ok
      assert wallet.address == context.user_wallet.address

      assert wallet.balances == [
               %{token: context.btc, amount: 990_000 * context.btc.subunit_to_unit},
               %{token: context.omg, amount: 57_000 * context.omg.subunit_to_unit},
               %{token: context.knc, amount: 0}
             ]
    end

    test "retrieve all wallets from a provider_user_id", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        150_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        12_000 * context.omg.subunit_to_unit
      )

      {status, wallet} =
        BalanceFetcher.all(%{"provider_user_id" => context.user.provider_user_id})

      assert status == :ok
      assert wallet.address == context.user_wallet.address

      assert wallet.balances == [
               %{token: context.btc, amount: 150_000 * context.btc.subunit_to_unit},
               %{token: context.omg, amount: 12_000 * context.omg.subunit_to_unit},
               %{token: context.knc, amount: 0}
             ]
    end
  end

  describe "get/2" do
    test "retrieve the specific wallet from a token and an address", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        150_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        12_000 * context.omg.subunit_to_unit
      )

      {status, wallet} = BalanceFetcher.get(context.omg.id, context.user_wallet)

      assert status == :ok
      assert wallet.address == context.user_wallet.address

      assert wallet.balances == [
               %{token: context.omg, amount: 12_000 * context.omg.subunit_to_unit}
             ]
    end
  end
end
