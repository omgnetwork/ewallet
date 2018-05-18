defmodule EWallet.WalletFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.WalletFetcher
  alias EWalletDB.{User, Wallet}

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()
    minted_token = insert(:minted_token)
    wallet = User.get_primary_wallet(user)

    %{user: user, minted_token: minted_token, wallet: wallet}
  end

  describe "get_wallet/2" do
    test "retrieves the user's primary wallet if address is nil", meta do
      {:ok, wallet} = WalletFetcher.get(meta.user, nil)
      assert wallet == User.get_primary_wallet(meta.user)
    end

    test "retrieves the wallet if address is given and belonds to the user", meta do
      inserted_wallet = insert(:wallet, identifier: Wallet.secondary(), user: meta.user)
      {:ok, wallet} = WalletFetcher.get(meta.user, inserted_wallet.address)
      assert wallet.uuid == inserted_wallet.uuid
    end

    test "returns 'wallet_not_found' if the address is not found", meta do
      {:error, error} = WalletFetcher.get(meta.user, "fake")
      assert error == :wallet_not_found
    end

    test "returns 'user_wallet_mismatch' if the wallet found does not belong to the user", meta do
      wallet = insert(:wallet)
      {:error, error} = WalletFetcher.get(meta.user, wallet.address)
      assert error == :user_wallet_mismatch
    end
  end
end
