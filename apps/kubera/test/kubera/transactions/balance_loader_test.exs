defmodule Kubera.Transactions.BalanceLoaderTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias Kubera.Transaction
  alias Kubera.Transactions.BalanceLoader
  alias KuberaDB.{Repo, User, MintedToken}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
    {:ok, user} = User.insert(params_for(:user))
    {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
    %{user: user, inserted_token: inserted_token}
  end

  describe "load/1" do
    test "loads the correct balances when credit", meta do
      {minted_token, from, to} = BalanceLoader.load(meta.user,
                                                    meta.inserted_token,
                                                    Transaction.credit_type)

      assert minted_token == meta.inserted_token
      assert from == MintedToken.get_master_balance(minted_token)
      assert to == User.get_main_balance(meta.user)
    end

    test "loads the correct balances when debit", meta do
      {minted_token, from, to} = BalanceLoader.load(meta.user,
                                                    meta.inserted_token,
                                                    Transaction.debit_type)

      assert minted_token == meta.inserted_token
      assert from == User.get_main_balance(meta.user)
      assert to == MintedToken.get_master_balance(minted_token)
    end
  end
end
