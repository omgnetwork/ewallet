defmodule EWallet.WalletAssigner do
  @moduledoc """
  Handles the load of the wallets of the user and minted_token
  """
  alias EWalletDB.{User, Account}
  alias EWallet.TransactionGate

  def assign(%{
        account: account,
        user: user,
        type: type,
        burn_wallet_identifier: burn_wallet_identifier
      }) do
    credit = TransactionGate.credit_type()
    debit = TransactionGate.debit_type()
    user_wallet = User.get_preloaded_primary_wallet(user)

    case type do
      ^credit ->
        account_wallet = Account.get_preloaded_primary_wallet(account)
        {:ok, account_wallet, user_wallet}

      ^debit ->
        case get_account_wallet(burn_wallet_identifier, account) do
          nil -> {:error, :burn_wallet_not_found}
          account_wallet -> {:ok, user_wallet, account_wallet}
        end
    end
  end

  defp get_account_wallet(nil, account) do
    Account.get_preloaded_primary_wallet(account)
  end

  defp get_account_wallet(identifier, account) do
    Account.get_wallet_by_identifier(account, identifier)
  end
end
