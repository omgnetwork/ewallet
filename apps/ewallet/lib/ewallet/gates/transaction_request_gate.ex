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

  @spec get_with_lock(UUID.t) :: {:ok, TransactionRequest.t} |
                                 {:error, :transaction_request_not_found}
  def get_with_lock(id) do
    request = TransactionRequest.get_with_lock(id)

    case request do
      nil     -> {:error, :transaction_request_not_found}
      request -> {:ok, request}
    end
  end

  @spec allow_amount_override?(TransactionRequest.t, Integer.t) ::
        {:ok, TransactionRequest.t} | {:error, :unauthorized_amount_override}
  def allow_amount_override?(request, amount) do
    case request.allow_amount_override do
      true  ->
        {:ok, request}
      false ->
        case amount do
          nil     -> {:ok, request}
          _amount -> {:error, :unauthorized_amount_override}
        end
    end
  end

  @spec expiration_from_lifetime(TransactionRequest.t) :: NaiveDateTime.t | nil
  def expiration_from_lifetime(request) do
    TransactionRequest.expiration_from_lifetime(request)
  end

  @spec expire_if_past_expiration_date(TransactionRequest.t) :: {:ok, TransactionRequest.t} |
                                                          {:error, Atom.t} |
                                                          {:error, Map.t}
  def expire_if_past_expiration_date(request) do
    res = TransactionRequest.expire_if_past_expiration_date(request)

    case res do
      {:ok, %TransactionRequest{status: "expired"} = request} ->
        {:error, String.to_existing_atom(request.expiration_reason)}
      {:ok, request} ->
        {:ok, request}
      {:error, error} ->
        {:error, error}
    end
  end

  @spec expire_if_max_consumption(TransactionRequest.t) :: {:ok, TransactionRequest.t} |
                                                          {:error, Map.t}
  def expire_if_max_consumption(request) do
    TransactionRequest.expire_if_max_consumption(request)
  end

  @spec valid?(TransactionRequest.t) :: {:ok, TransactionRequest.t} |
                                                          {:error, Atom.t}
  def valid?(request) do
    case TransactionRequest.valid?(request) do
      true  -> {:ok, request}
      false -> {:error, String.to_existing_atom(request.expiration_reason)}
    end
  end

  defp insert(minted_token, balance, attrs) do
   confirmable = if(is_nil(attrs["confirmable"]), do: false, else: attrs["confirmable"])
   allow_amount_override = if(is_nil(attrs["allow_amount_override"]),
                              do: true, else: attrs["allow_amount_override"])
    TransactionRequest.insert(%{
      type: attrs["type"],
      correlation_id: attrs["correlation_id"],
      amount: attrs["amount"],
      user_id: balance.user_id,
      account_id: balance.account_id,
      minted_token_id: minted_token.id,
      balance_address: balance.address,
      allow_amount_override: allow_amount_override,
      confirmable: confirmable,
      consumption_lifetime: attrs["consumption_lifetime"],
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{},
      expiration_date: attrs["expiration_date"],
      max_consumptions: attrs["max_consumptions"]
    })
  end
end
