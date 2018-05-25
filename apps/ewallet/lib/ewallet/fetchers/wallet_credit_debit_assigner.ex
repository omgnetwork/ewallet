defmodule EWallet.WalletCreditDebitAssigner do
  @moduledoc """
  Handles the load of the wallets of the user and token
  """
  alias EWallet.{TransactionGate, WalletFetcher}

  def assign(%{
        account: account,
        account_address: account_address,
        user: user,
        user_address: user_address,
        type: type
      }) do
    with {:ok, user_wallet} <- WalletFetcher.get(user, user_address),
         {:ok, account_wallet} <- WalletFetcher.get(account, account_address) do
      credit = TransactionGate.credit_type()
      debit = TransactionGate.debit_type()

      case type do
        ^credit ->
          {:ok, account_wallet, user_wallet}

        ^debit ->
          {:ok, user_wallet, account_wallet}
      end
    else
      error -> error
    end
  end
end
