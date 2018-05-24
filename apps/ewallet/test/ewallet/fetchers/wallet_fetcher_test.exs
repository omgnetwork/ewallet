defmodule EWallet.WalletFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.WalletFetcher
  alias EWalletDB.{User, Wallet}

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()
    {:ok, account} = :account |> params_for() |> Account.insert()
    token = insert(:token)
    wallet = User.get_primary_wallet(user)

    %{user: user, account: account, token: token, wallet: wallet}
  end

  describe "get/2" do
    test "retrieves the user's primary wallet if address is nil", meta do
      {:ok, wallet} = WalletFetcher.get(meta.user, nil)
      assert wallet == User.get_primary_wallet(meta.user)
    end

    test "retrieves the wallet if address is given and belongs to the user", meta do
      inserted_wallet = insert(:wallet, identifier: Wallet.secondary(), user: meta.user)
      {:ok, wallet} = WalletFetcher.get(meta.user, inserted_wallet.address)
      assert wallet.uuid == inserted_wallet.uuid
    end

    test "returns 'user_wallet_not_found' if the address is not found", meta do
      {:error, error} = WalletFetcher.get(meta.user, "fake")
      assert error == :user_wallet_not_found
    end

    test "returns 'user_wallet_mismatch' if the wallet found does not belong to the user", meta do
      wallet = insert(:wallet)
      {:error, error} = WalletFetcher.get(meta.user, wallet.address)
      assert error == :user_wallet_mismatch
    end

    test "returns 'account_wallet_not_found' if the address is not found", meta do
      {:error, error} = WalletFetcher.get(meta.account, "fake")
      assert error == :account_wallet_not_found
    end

    test "returns 'account_wallet_mismatch' if the wallet found does not belong to the account",
         meta do
      wallet = insert(:wallet)
      {:error, error} = WalletFetcher.get(meta.account, wallet.address)
      assert error == :account_wallet_mismatch
    end
  end
end
