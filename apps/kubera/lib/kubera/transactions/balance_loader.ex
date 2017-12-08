defmodule Kubera.Transactions.BalanceLoader do
  @moduledoc """
  Handles the load of the balances of the user and minted_token
  """
  alias KuberaDB.{User, Account}
  alias Kubera.Transaction

  def load(account, user, type, burn_balance_identifier) do
    assign_balances(account, user, type, burn_balance_identifier)
  end

  defp assign_balances(account, user, type, burn_balance_identifier) do
    credit = Transaction.credit_type()
    debit = Transaction.debit_type()
    user_balance = User.get_primary_balance(user)

    case type do
      ^credit ->
        account_balance = Account.get_primary_balance(account)
        {:ok, account_balance, user_balance}
      ^debit ->
        case get_account_balance(burn_balance_identifier, account) do
          nil -> {:error, :burn_balance_not_found}
          account_balance -> {:ok, user_balance, account_balance}
        end
    end
  end

  defp get_account_balance(nil, account) do
    Account.get_primary_balance(account)
  end
  defp get_account_balance(identifier, account) do
    Account.get_balance_by_identifier(account, identifier)
  end
end
