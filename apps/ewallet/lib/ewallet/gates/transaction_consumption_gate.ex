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
    # is it expired? -> {:error, expired}
    # is there a number of max consumption? -> lock table
    # is it confirmable? -> return a pending request, call  to websocket
    # is there a lifetime?
    # it's not? -> create
    # max consumption ? -> increment
    # unlock table
    with {:ok, request} <- TransactionRequestGate.get(request_id),
         {:ok, minted_token} <- get_minted_token(token_id),
         {:ok, consumption} <- insert(balance, minted_token, request, attrs),
         {:ok, consumption} <- get(consumption.id)
    do
      case request.confirmable do
        true ->
          EWallet.Event.dispatch(:transaction_request_confirmation, %{
            consumption: consumption
          })

          {:ok, consumption}
        false ->
          consumption
          |> TransactionRequestConsumption.approve()
          |> transfer(request.type)
      end
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

  def confirm(id) do
    with {:ok, consumption} <- get(id)
    do
      # What happens if the consumption is approved but the
      # transfer fails?
      consumption
      |> TransactionRequestConsumption.approve()
      |> transfer(consumption.transaction_request.type)
    else
      error -> error
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
      balance_address: balance.address,
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{}
    })
  end

  defp transfer(consumption, "send") do
    from = consumption.transaction_request.balance_address
    to = consumption.balance.address
    transfer(consumption, from, to)
  end

  defp transfer(consumption, "receive") do
    from = consumption.balance.address
    to = consumption.transaction_request.balance_address
    transfer(consumption, from, to)
  end

  defp transfer(consumption, from, to) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => from,
      "to_address" => to,
      "token_id" => consumption.minted_token.friendly_id,
      "amount" => consumption.amount,
      "metadata" => consumption.metadata,
      "encrypted_metadata" => consumption.encrypted_metadata
    }

    case TransactionGate.process_with_addresses(attrs) do
      {:ok, transfer, _, _} ->
        consumption = TransactionRequestConsumption.confirm(consumption, transfer)
        {:ok, consumption}
      {:error, transfer, code, description} ->
        consumption = TransactionRequestConsumption.fail(consumption, transfer)
        {:error, consumption, code, description}
    end
  end
end
