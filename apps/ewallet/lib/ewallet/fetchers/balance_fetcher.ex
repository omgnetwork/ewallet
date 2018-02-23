defmodule EWallet.BalanceFetcher do
  @moduledoc """

  """
  alias EWalletDB.{User, Balance, Account}

  @spec get(User.t, String.t) :: {:ok, Balance.t} | {:error, Atom.t}
  def get(%User{} = user, nil) do
    {:ok, User.get_primary_balance(user)}
  end

  def get(%Account{} = account, nil) do
    {:ok, Account.get_primary_balance(account)}
  end

  def get(nil, address) do
    with %Balance{} = balance <- Balance.get(address) || :balance_not_found
    do
      {:ok, balance}
    else
      error -> {:error, error}
    end
  end

  def get(%User{} = user, address) do
    with %Balance{} = balance <- Balance.get(address) || :balance_not_found,
         true <- balance.user_id == user.id || :user_balance_mismatch
    do
      {:ok, balance}
    else
      error -> {:error, error}
    end
  end

  def get(%Account{} = account, address) do
    with %Balance{} = balance <- Balance.get(address) || :balance_not_found,
         true <- balance.account_id == account.id || :account_balance_mismatch
    do
      {:ok, balance}
    else
      error -> {:error, error}
    end
  end
end
