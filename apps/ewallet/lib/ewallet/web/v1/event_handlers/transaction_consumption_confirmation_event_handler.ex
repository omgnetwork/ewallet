defmodule EWallet.Web.V1.TransactionConsumptionEventHandler do
  @moduledoc """
  This module represents the transaction_consumption_confirmation event and how to build it.
  """
  alias  EWallet.Web.V1.{Event, TransactionConsumptionSerializer}
  alias EWalletDB.TransactionConsumption

  @spec broadcast(Atom.t, TransactionConsumption.t) :: :ok | {:error, :unhandled_event}
  def broadcast(:transaction_consumption_request, %{consumption: consumption}) do
    topics =
      []
      |> Event.address_topic(consumption.transaction_request.balance_address)
      |> Event.transaction_request_topic(consumption.transaction_request_id)
      |> Event.user_topic(consumption.transaction_request.user_id)
      |> Event.account_topic(consumption.transaction_request.account_id)

    Event.broadcast(
      event: "transaction_consumption_request",
      topics: topics,
      payload: payload(consumption)
    )
  end

  def broadcast(:transaction_consumption_approved, %{consumption: consumption}) do
    broadcast_change("transaction_consumption_approved", consumption)
  end

  def broadcast(:transaction_consumption_rejected, %{consumption: consumption}) do
    broadcast_change("transaction_consumption_rejected", consumption)
  end

  def broadcast(_, _), do: {:error, :unhandled_event}

  defp broadcast_change(event, consumption) do
    topics =
      []
      |> Event.address_topic(consumption.balance_address)
      |> Event.transaction_request_topic(consumption.transaction_request_id)
      |> Event.transaction_consumption_topic(consumption.id)
      |> Event.user_topic(consumption.user_id)
      |> Event.account_topic(consumption.account_id)

    Event.broadcast(
      event: event,
      topics: topics,
      payload: payload(consumption)
    )
  end

  defp payload(consumption) do
    consumption
    |> TransactionConsumptionSerializer.serialize()
  end
end
