defmodule EWallet.TransactionRequestGate do
  @moduledoc """
  Business logic to manage transaction requests. This module is responsible
  for creating new requests, retrieving existing ones and handles the logic
  of picking the right wallet when inserting a new request.

  It is basically an interface to the EWalletDB.TransactionRequest schema.
  """
  alias EWallet.{WalletFetcher, TransactionRequestFetcher}
  alias EWalletDB.{TransactionRequest, User, Wallet, Token, Account}

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
         {:ok, wallet} <- WalletFetcher.get(user, address),
         wallet <- Map.put(wallet, :account_uuid, account.uuid),
         {:ok, transaction_request} <- create(wallet, attrs) do
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
         {:ok, wallet} <- WalletFetcher.get(account, address),
         {:ok, transaction_request} <- create(wallet, attrs) do
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
         {:ok, wallet} <- WalletFetcher.get(user, address),
         {:ok, transaction_request} <- create(wallet, attrs) do
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
    with {:ok, wallet} <- WalletFetcher.get(nil, address),
         {:ok, transaction_request} <- create(wallet, attrs) do
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
    with {:ok, wallet} <- WalletFetcher.get(user, address) do
      create(wallet, attrs)
    else
      error -> error
    end
  end

  @spec create(Wallet.t(), Map.t()) :: {:ok, TransactionRequest.t()} | {:error, Atom.t()}
  def create(
        %Wallet{} = wallet,
        %{
          "type" => _,
          "correlation_id" => _,
          "amount" => _,
          "token_id" => token_id
        } = attrs
      ) do
    with %Token{} = token <- Token.get(token_id) || :token_not_found,
         {:ok, transaction_request} <- insert(token, wallet, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(_, _attrs), do: {:error, :invalid_parameter}

  @spec expire_if_past_expiration_date(TransactionRequest.t()) ::
          {:ok, TransactionRequest.t()}
          | {:error, Atom.t()}
          | {:error, Map.t()}
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

  defp insert(token, wallet, attrs) do
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
      user_uuid: wallet.user_uuid,
      account_uuid: wallet.account_uuid,
      token_uuid: token.uuid,
      wallet_address: wallet.address,
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
