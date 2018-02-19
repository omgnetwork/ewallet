defmodule EWallet.TransactionRequests.BalanceLoaderTest do
 use EWallet.LocalLedgerCase, async: true
 alias EWallet.TransactionRequests.BalanceLoader
 alias EWalletDB.{User, Balance}

  setup do
    {:ok, user}  = :user |> params_for() |> User.insert()
    minted_token = insert(:minted_token)
    balance      = User.get_primary_balance(user)

    %{user: user, minted_token: minted_token, balance: balance}
  end

  describe "get_balance/2" do
    test "retrieves the user's primary balance if address is nil", meta do
      {:ok, balance} = BalanceLoader.get(meta.user, nil)
      assert balance == User.get_primary_balance(meta.user)
    end

    test "retrieves the balance if address is given and belonds to the user", meta do
      inserted_balance = insert(:balance, identifier: Balance.secondary, user: meta.user)
      {:ok, balance} = BalanceLoader.get(meta.user, inserted_balance.address)
      assert balance.id == inserted_balance.id
    end

    test "returns 'balance_not_found' if the address is not found", meta do
      {:error, error} = BalanceLoader.get(meta.user, "fake")
      assert error == :balance_not_found
    end

    test "returns 'user_balance_mismatch' if the balance found does not belong to the user",
    meta do
      balance = insert(:balance)
      {:error, error} = BalanceLoader.get(meta.user, balance.address)
      assert error == :user_balance_mismatch
    end
  end
end
