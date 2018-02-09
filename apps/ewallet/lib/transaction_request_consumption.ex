defmodule EWallet.TransactionRequestConsumption do
  @moduledoc """
  Business logic to manage transaction request consumptions.
  """
  alias EWallet.Transaction
  alias EWalletDB.TransactionRequestConsumption

  def insert(%{
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
      user: user,
      transaction_request: request,
      balance: balance
    })
  end

  def consume("receive", consumption, metadata) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => consumption.balance.address,
      "to_address" => consumption.transaction_request.balance.address,
      "token_id" => consumption.transaction_request.minted_token.friendly_id,
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

  # def consume("send", _consumption, _metadata) do
  #   # Coming Soon
  # end
end
