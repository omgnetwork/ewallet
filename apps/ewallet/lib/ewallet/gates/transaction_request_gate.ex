defmodule EWallet.TransactionRequestGate do
  @moduledoc """
  Business logic to manage transaction requests. This module is responsible
  for creating new requests, retrieving existing ones and handles the logic
  of picking the right balance when inserting a new request.

  It is basically an interface to the EWalletDB.TransactionRequest schema.
  """
  alias EWallet.{
    BalanceFetcher,
    TransactionRequestFetcher
  }

  alias EWalletDB.{TransactionRequest, User, Balance, MintedToken, Account}

  @spec create(Map.t()) :: {:ok, TransactionRequest.t()} | {:error, Atom.t()}

  def create(
        %{
          "account_id" => account_id,
          "provider_user_id" => provider_user_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || :account_id_not_found,
         %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found,
         {:ok, balance} <- BalanceFetcher.get(user, address),
         balance <- Map.put(balance, :account_uuid, account.uuid),
         {:ok, transaction_request} <- create(balance, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(
        %{
          "account_id" => account_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || :account_id_not_found,
         {:ok, balance} <- BalanceFetcher.get(account, address),
         {:ok, transaction_request} <- create(balance, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(%{"account_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> create()
  end

  def create(
        %{
          "provider_user_id" => provider_user_id,
          "address" => address
        } = attrs
      ) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found,
         {:ok, balance} <- BalanceFetcher.get(user, address),
         {:ok, transaction_request} <- create(balance, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(%{"provider_user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> create()
  end

  def create(
        %{
          "address" => address
        } = attrs
      ) do
    with {:ok, balance} <- BalanceFetcher.get(nil, address),
         {:ok, transaction_request} <- create(balance, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(_), do: {:error, :invalid_parameter}

  @spec create(User.t(), Map.t()) :: {:ok, TransactionRequest.t()} | {:error, Atom.t()}
  def create(
        %User{} = user,
        %{
          "address" => address
        } = attrs
      ) do
    with {:ok, balance} <- BalanceFetcher.get(user, address) do
      create(balance, attrs)
    else
      error -> error
    end
  end

  @spec create(Balance.t(), Map.t()) :: {:ok, TransactionRequest.t()} | {:error, Atom.t()}
  def create(
        %Balance{} = balance,
        %{
          "type" => _,
          "correlation_id" => _,
          "amount" => _,
          "token_id" => token_id
        } = attrs
      ) do
    with %MintedToken{} = minted_token <- MintedToken.get(token_id) || :minted_token_not_found,
         {:ok, transaction_request} <- insert(minted_token, balance, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(_, _attrs), do: {:error, :invalid_parameter}

  defp insert(minted_token, balance, attrs) do
    require_confirmation =
      if(
        is_nil(attrs["require_confirmation"]),
        do: false,
        else: attrs["require_confirmation"]
      )

    allow_amount_override =
      if(
        is_nil(attrs["allow_amount_override"]),
        do: true,
        else: attrs["allow_amount_override"]
      )

    TransactionRequest.insert(%{
      type: attrs["type"],
      correlation_id: attrs["correlation_id"],
      amount: attrs["amount"],
      user_uuid: balance.user_uuid,
      account_uuid: balance.account_uuid,
      minted_token_uuid: minted_token.uuid,
      balance_address: balance.address,
      allow_amount_override: allow_amount_override,
      require_confirmation: require_confirmation,
      consumption_lifetime: attrs["consumption_lifetime"],
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{},
      expiration_date: attrs["expiration_date"],
      max_consumptions: attrs["max_consumptions"],
      max_consumptions_per_user: attrs["max_consumptions_per_user"]
    })
  end
end
