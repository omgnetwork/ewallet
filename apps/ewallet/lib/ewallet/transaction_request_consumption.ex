defmodule EWallet.TransactionRequestConsumption do
  @moduledoc """
  Business logic to manage transaction request consumptions.
  """
  alias EWallet.{Transaction, TransactionRequest}
  alias EWalletDB.TransactionRequestConsumption

  def get(id) do
    TransactionRequestConsumption.get(id, preload: [
      :user, :balance, :minted_token, :transaction_request
    ])
  end

  def insert(%{
    user: user,
    idempotency_token: idempotency_token,
    request: request,
    balance: balance,
    attrs: attrs
  }) do
    {:ok, _consumption} = TransactionRequestConsumption.insert(%{
      correlation_id: attrs["correlation_id"],
      idempotency_token: idempotency_token,
      amount: attrs["amount"] || request.amount,
      user_id: user.id,
      minted_token_id: request.minted_token_id,
      transaction_request_id: request.id,
      balance_address: balance.address
    })
  end

  def consume("receive", consumption, metadata) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => consumption.balance.address,
      "to_address" => consumption.transaction_request.balance_address,
      "token_id" => consumption.minted_token.friendly_id,
      "amount" => consumption.amount,
      "metadata" => metadata
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
