defmodule EWallet.TransactionRequests.Consumption do
  @moduledoc """
  Business logic to manage transaction request consumptions. This module is responsible for
  creating new consumptions, generating transfers and transactions. It can also be used to
  retrieve a specific consumption.

  It is basically an interface to the EWalletDB.TransactionRequestConsumption schema.
  """
  alias EWallet.Transaction
  alias EWallet.TransactionRequests.{Request, BalanceLoader}
  alias EWalletDB.{TransactionRequestConsumption}

  @spec consume(User.t, String.t, Map.t) :: {:ok, TransactionRequestConsumption.t} |
                                            {:error, Atom.t}
  def consume(user, idempotency_token, %{
    "transaction_request_id" => request_id,
    "correlation_id" => _,
    "amount" => _,
    "address" => address,
    "metadata" => metadata
  } = attrs) do
    with {:ok, request} <- Request.get(request_id),
         {:ok, balance} <- BalanceLoader.get(user, address),
         {:ok, consumption} <- insert(%{
           user: user,
           idempotency_token: idempotency_token,
           request: request,
           balance: balance,
           attrs: attrs
         }),
         {:ok, consumption} <- get(consumption.id)
    do
      transfer(request.type, consumption, metadata)
    else
      error when is_atom(error) -> {:error, error}
      error                     -> error
    end
  end
  def consume(_user, _idempotency_token, _attrs) do
    {:error, :invalid_parameter}
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

  defp insert(%{
    user: user,
    idempotency_token: idempotency_token,
    request: request,
    balance: balance,
    attrs: attrs
  }) do
    TransactionRequestConsumption.insert(%{
      correlation_id: attrs["correlation_id"],
      idempotency_token: idempotency_token,
      amount: attrs["amount"] || request.amount,
      user_id: user.id,
      minted_token_id: request.minted_token_id,
      transaction_request_id: request.id,
      balance_address: balance.address
    })
  end

  defp transfer("receive", consumption, metadata) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => consumption.balance.address,
      "to_address" => consumption.transaction_request.balance_address,
      "token_id" => consumption.minted_token.friendly_id,
      "amount" => consumption.amount,
      "metadata" => metadata || %{}
    }

    case Transaction.process_with_addresses(attrs) do
      {:ok, transfer, _, _} ->
        consumption = TransactionRequestConsumption.confirm(consumption, transfer)
        {:ok, consumption}
      {:error, transfer, code, description} ->
        TransactionRequestConsumption.fail(consumption, transfer)
        {:error, code, description}
    end
  end
end
