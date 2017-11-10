defmodule Kubera.Transactions.BalanceLoader do
  @moduledoc """
  Handles the load of the balances of the user and minted_token
  """
  alias Kubera.Transaction
  alias KuberaDB.{User, MintedToken}

  def load(user, minted_token, type) do
    user_balance = User.get_main_balance(user)
    master_balance = MintedToken.get_master_balance(minted_token)
    {from, to} = assign_balances(master_balance, user_balance, type)

    {minted_token, from, to}
  end

  defp assign_balances(master_balance, user_balance, type) do
    credit = Transaction.credit_type
    debit = Transaction.debit_type

    case type do
      ^credit -> {master_balance, user_balance}
      ^debit -> {user_balance, master_balance}
    end
  end
end
