defmodule EWallet.TransactionRequest do
  @moduledoc """
  Business logic to manage transaction requests.
  """
  alias EWalletDB.{TransactionRequest, User, Balance}

  def get_balance(user, nil) do
    User.get_primary_balance(user)
  end
  def get_balance(user, address) do
    with %Balance{} = balance <- Balance.get(address) || :balance_not_found,
         true <- balance.user_id == user.id || :user_balance_mismatch
    do
      balance
    else
      error -> error
    end
  end

  def get(id) do
    TransactionRequest.get(id, preload: [:minted_token, :user, :balance])
  end

  def insert(user, minted_token, balance, attrs) do
    TransactionRequest.insert(%{
      type: attrs["type"],
      correlation_id: attrs["correlation_id"],
      amount: attrs["amount"],
      user_id: user.id,
      minted_token_id: minted_token.id,
      balance_address: balance.address
    })
  end
end
