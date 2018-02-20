defmodule EWallet.Transactions.Request do
  @moduledoc """
  Business logic to manage transaction requests. This module is responsible
  for creating new requests, retrieving existing ones and handles the logic
  of picking the right balance when inserting a new request.

  It is basically an interface to the EWalletDB.TransactionRequest schema.
  """
  alias EWalletDB.{TransactionRequest, User, Balance, MintedToken}

  @spec create(User.t, Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}
  def create(user, %{
    "type" => _,
    "correlation_id" => _,
    "amount" => _,
    "token_id" => token_id,
    "address" => address,
  } = attrs) do
    with %MintedToken{} = minted_token <- MintedToken.get(token_id) || :minted_token_not_found,
         {:ok, balance} <- get_balance(user, address),
         {:ok, transaction_request} <- insert(user, minted_token, balance, attrs)
    do
      get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end
  def create(nil, _attrs),   do: {:error, :invalid_parameter}
  def create(_user, _attrs), do: {:error, :invalid_parameter}

  @spec get_balance(User.t, String.t) :: {:ok, Balance.t} | {:error, Atom.t}
  def get_balance(user, nil) do
    {:ok, User.get_primary_balance(user)}
  end
  def get_balance(user, address) do
    with %Balance{} = balance <- Balance.get(address) || :balance_not_found,
         true <- balance.user_id == user.id || :user_balance_mismatch
    do
      {:ok, balance}
    else
      error -> {:error, error}
    end
  end

  @spec get(UUID.t) :: {:ok, TransactionRequest.t} | {:error, :transaction_request_not_found}
  def get(id) do
    request = TransactionRequest.get(id, preload: [:minted_token, :user, :balance])

    case request do
      nil     -> {:error, :transaction_request_not_found}
      request -> {:ok, request}
    end
  end

  defp insert(user, minted_token, balance, attrs) do
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
