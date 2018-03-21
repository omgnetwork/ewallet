defmodule EWallet.TransactionRequestGate do
  @moduledoc """
  Business logic to manage transaction requests. This module is responsible
  for creating new requests, retrieving existing ones and handles the logic
  of picking the right balance when inserting a new request.

  It is basically an interface to the EWalletDB.TransactionRequest schema.
  """
  alias EWallet.BalanceFetcher
  alias EWalletDB.{TransactionRequest, User, Balance, MintedToken, Account}

  @spec create(Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}

  def create(%{
    "account_id" => account_id,
    "address" => address
  } = attrs) do
    with %Account{} = account <- Account.get(account_id) || :account_id_not_found,
         {:ok, balance} <- BalanceFetcher.get(account, address),
         {:ok, transaction_request} <- create(balance, attrs)
    do
      get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end
  def create(%{"account_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> create()
  end

  def create(%{
    "provider_user_id" => provider_user_id,
    "address" => address
  } = attrs) do
    with %User{} = user <- User.get_by_provider_user_id(provider_user_id) ||
                           :provider_user_id_not_found,
         {:ok, balance} <- BalanceFetcher.get(user, address),
         {:ok, transaction_request} <- create(balance, attrs)
    do
      get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end
  def create(%{"provider_user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> create()
  end

  def create(%{
    "address" => address
  } = attrs) do
    with {:ok, balance} <- BalanceFetcher.get(nil, address),
         {:ok, transaction_request} <- create(balance, attrs)
    do
      get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end

  def create(_), do: {:error, :invalid_parameter}

  @spec create(User.t, Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}
  def create(%User{} = user, %{
    "address" => address
  } = attrs) do
    with {:ok, balance} <- BalanceFetcher.get(user, address)
    do create(balance, attrs)
    else error -> error
    end
  end

  @spec create(Balance.t, Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}
  def create(%Balance{} = balance, %{
    "type" => _,
    "correlation_id" => _,
    "amount" => _,
    "token_id" => token_id
  } = attrs) do
    with %MintedToken{} = minted_token <- MintedToken.get(token_id) || :minted_token_not_found,
         {:ok, transaction_request} <- insert(minted_token, balance, attrs)
    do
      get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end
  def create(_, _attrs),   do: {:error, :invalid_parameter}

  @spec get(UUID.t) :: {:ok, TransactionRequest.t} | {:error, :transaction_request_not_found}
  def get(id) do
    request = TransactionRequest.get(id, preload: [:minted_token, :user, :balance])

    case request do
      nil     -> {:error, :transaction_request_not_found}
      request -> {:ok, request}
    end
  end

  def get_with_lock(id) do
    request = TransactionRequest.get_with_lock(id)

    case request do
      nil     -> {:error, :transaction_request_not_found}
      request -> {:ok, request}
    end
  end

  def allow_amount_override?(request, amount) do
    case request.allow_amount_override do
      true  ->
        {:ok, request}
      false ->
        case amount do
          nil    -> {:ok, request}
          amount -> {:error, :unauthorized_amount_override}
        end
    end
  end

  def expiration_from_lifetime(request) do
    TransactionRequest.expiration_from_lifetime(request)
  end

  def limited_consumptions?(request) do
    TransactionRequest.limited_consumptions?(request)
  end

  def expire_if_max_consumption(request) do
    TransactionRequest.expire_if_max_consumption(request)
  end

  def valid?(request) do
    case TransactionRequest.valid?(request) do
      true  -> {:ok, request}
      false -> {:error, String.to_existing_atom(request.expiration_reason)}
    end
  end

  defp insert(minted_token, balance, attrs) do
    TransactionRequest.insert(%{
      type: attrs["type"],
      correlation_id: attrs["correlation_id"],
      amount: attrs["amount"],
      user_id: balance.user_id,
      account_id: balance.account_id,
      minted_token_id: minted_token.id,
      balance_address: balance.address
    })
  end
end
