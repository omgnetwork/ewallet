defmodule EWallet.WalletCreditDebitAssignerTest do
  use ExUnit.Case
  import EWalletDB.Factory
  alias EWallet.{TransactionGate, WalletCreditDebitAssigner}
  alias EWalletDB.{Repo, User, Account}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
    {:ok, user} = User.insert(params_for(:user))
    {:ok, account} = Account.insert(params_for(:account))

    %{account: account, user: user}
  end

  describe "load/1" do
    test "loads the correct wallets when credit", meta do
      {:ok, from, to} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: nil,
          user: meta.user,
          user_address: nil,
          type: TransactionGate.credit_type()
        })

      assert from == Account.get_primary_wallet(meta.account)
      assert to == User.get_primary_wallet(meta.user)
    end

    test "loads the correct wallets when debit", meta do
      {:ok, from, to} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: nil,
          user: meta.user,
          user_address: nil,
          type: TransactionGate.debit_type()
        })

      assert from == User.get_primary_wallet(meta.user)
      assert to == Account.get_primary_wallet(meta.account)
    end

    test "loads the correct wallets when debit and account_address is specified", meta do
      account_burn_address = Account.get_default_burn_wallet(meta.account).address

      {:ok, from, to} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: account_burn_address,
          user: meta.user,
          user_address: nil,
          type: TransactionGate.debit_type()
        })

      assert from == User.get_primary_wallet(meta.user)
      assert to == Account.get_default_burn_wallet(meta.account)
    end

    test "returns an error if the given account address is not found", meta do
      {res, code} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: "none-0000-0000-0000",
          user: meta.user,
          user_address: nil,
          type: TransactionGate.debit_type()
        })

      assert res == :error
      assert code == :account_wallet_not_found
    end

    test "returns an error if the given account address does not belong to the account", meta do
      wallet = insert(:wallet)

      {res, code} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: wallet.address,
          user: meta.user,
          user_address: nil,
          type: TransactionGate.debit_type()
        })

      assert res == :error
      assert code == :account_wallet_mismatch
    end

    test "loads the correct wallets when debit and user_address is specified", meta do
      user_secondary_wallet = insert(:wallet, user: meta.user, identifier: "secondary")

      {:ok, from, to} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: nil,
          user: meta.user,
          user_address: user_secondary_wallet.address,
          type: TransactionGate.debit_type()
        })

      assert from.address == user_secondary_wallet.address
      assert to == Account.get_primary_wallet(meta.account)
    end

    test "returns an error if the given user address is not found", meta do
      {res, code} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: nil,
          user: meta.user,
          user_address: "none-0000-0000-0000",
          type: TransactionGate.debit_type()
        })

      assert res == :error
      assert code == :user_wallet_not_found
    end

    test "returns an error if the given user address does not belong to the user", meta do
      wallet = insert(:wallet)

      {res, code} =
        WalletCreditDebitAssigner.assign(%{
          account: meta.account,
          account_address: nil,
          user: meta.user,
          user_address: wallet.address,
          type: TransactionGate.debit_type()
        })

      assert res == :error
      assert code == :user_wallet_mismatch
    end
  end
end
