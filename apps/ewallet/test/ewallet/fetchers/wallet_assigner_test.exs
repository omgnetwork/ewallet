defmodule EWallet.WalletAssignerTest do
  use ExUnit.Case
  import EWalletDB.Factory
  alias EWallet.{TransactionGate, WalletAssigner}
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
        WalletAssigner.assign(%{
          account: meta.account,
          user: meta.user,
          type: TransactionGate.credit_type(),
          burn_wallet_identifier: nil
        })

      assert from == Account.get_primary_wallet(meta.account)
      assert to == User.get_primary_wallet(meta.user)
    end

    test "loads the correct wallets when debit", meta do
      {:ok, from, to} =
        WalletAssigner.assign(%{
          account: meta.account,
          user: meta.user,
          type: TransactionGate.debit_type(),
          burn_wallet_identifier: nil
        })

      assert from == User.get_primary_wallet(meta.user)
      assert to == Account.get_primary_wallet(meta.account)
    end

    test "loads the correct wallets when debit and burn wallet is specified", meta do
      {:ok, from, to} =
        WalletAssigner.assign(%{
          account: meta.account,
          user: meta.user,
          type: TransactionGate.debit_type(),
          burn_wallet_identifier: "burn"
        })

      assert from == User.get_primary_wallet(meta.user)
      assert to == Account.get_default_burn_wallet(meta.account)
    end

    test "returns an error if the given burn address is not found", meta do
      {res, code} =
        WalletAssigner.assign(%{
          account: meta.account,
          user: meta.user,
          type: TransactionGate.debit_type(),
          burn_wallet_identifier: "burnz"
        })

      assert res == :error
      assert code == :burn_wallet_not_found
    end
  end
end
