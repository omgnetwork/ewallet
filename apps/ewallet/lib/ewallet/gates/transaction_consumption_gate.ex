defmodule EWallet.TransactionConsumptionGate do
  @moduledoc """
  Business logic to manage transaction request consumptions. This module is responsible for
  creating new consumptions, generating transfers and transactions. It can also be used to
  retrieve a specific consumption.

  It is basically an interface to the EWalletDB.TransactionRequestConsumption schema.
  """
  alias EWallet.{TransactionGate, TransactionRequestGate, BalanceFetcher}
  alias EWalletDB.{Account, MintedToken, User, Balance, TransactionRequestConsumption}

  @spec consume(Map.t) :: {:ok, TransactionRequestConsumption.t} | {:error, Atom.t}
  def consume(%{
    "account_id" => account_id,
    "address" => address
  } = attrs) do
    with %Account{} = account <- Account.get(account_id) || :account_id_not_found,
         {:ok, balance} <- BalanceFetcher.get(account, address)
    do
      consume(balance, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end

  def consume(%{"account_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> consume()
  end

  def consume(%{
    "provider_user_id" => provider_user_id,
    "address" => address
  } = attrs) do
    with %User{} = user <- User.get_by_provider_user_id(provider_user_id) ||
                           :provider_user_id_not_found,
         {:ok, balance} <- BalanceFetcher.get(user, address)
    do
      consume(balance, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end

  def consume(%{"provider_user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> consume()
  end

  def consume(%{
    "address" => address
  } = attrs) do
    with {:ok, balance} <- BalanceFetcher.get(nil, address)
    do
      consume(balance, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end

  def consume(_attrs), do: {:error, :invalid_parameter}

  @spec consume(User.t, Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}
  def consume(%User{} = user, %{
    "address" => address
  } = attrs) do
    with {:ok, balance} <- BalanceFetcher.get(user, address)
    do
      consume(balance, attrs)
    else
      error -> error
    end
  end

  @spec consume(Balance.t, Map.t) :: {:ok, TransactionRequest.t} | {:error, Atom.t}
  def consume(%Balance{} = balance, %{
    "transaction_request_id" => request_id,
    "correlation_id" => _,
    "amount" => _,
    "token_id" => token_id,
    "idempotency_token" => _
  } = attrs) do
    with {:ok, request} <- TransactionRequestGate.get(request_id),
         {:ok, minted_token} <- get_minted_token(token_id),
         {:ok, consumption} <- insert(balance, minted_token, request, attrs),
         {:ok, consumption} <- get(consumption.id)
    do
      transfer(request.type, consumption, attrs["metadata"], attrs["encrypted_metadata"])
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end

  def consume(_, _attrs), do: {:error, :invalid_parameter}

   defp get_minted_token(nil), do: {:ok, nil}
   defp get_minted_token(token_id) do
      case MintedToken.get(token_id) do
        nil          -> :minted_token_not_found
        minted_token -> minted_token
      end
   end

  @spec get(UUID.t) :: {:ok, TransactionRequestConsumption.t} |
                       {:error, :transaction_request_consumption_not_found}
  def get(id) do
    consumption = TransactionRequestConsumption.get(id, preload: [
      :user, :balance, :minted_token, :transaction_request
    ])

    case consumption do
      nil         -> {:error, :transaction_request_consumption_not_found}
      consumption -> {:ok, consumption}
    end
  end

  defp insert(balance, minted_token, request, attrs) do
    TransactionRequestConsumption.insert(%{
      correlation_id: attrs["correlation_id"],
      idempotency_token: attrs["idempotency_token"],
      amount: attrs["amount"] || request.amount,
      user_id: balance.user_id,
      account_id: balance.account_id,
      minted_token_id: if(minted_token, do: minted_token.id, else: request.minted_token_id),
      transaction_request_id: request.id,
      balance_address: balance.address
    })
  end

  defp transfer("receive", consumption, metadata, encrypted_metadata) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => consumption.balance.address,
      "to_address" => consumption.transaction_request.balance_address,
      "token_id" => consumption.minted_token.friendly_id,
      "amount" => consumption.amount,
      "metadata" => metadata,
      "encrypted_metadata" => encrypted_metadata
    }

    case TransactionGate.process_with_addresses(attrs) do
      {:ok, transfer, _, _} ->
        consumption = TransactionRequestConsumption.confirm(consumption, transfer)
        {:ok, consumption}
      {:error, transfer, code, description} ->
        TransactionRequestConsumption.fail(consumption, transfer)
        {:error, code, description}
    end
  end
end
