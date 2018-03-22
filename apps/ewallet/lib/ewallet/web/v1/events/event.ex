defmodule EWallet.Web.V1.Event do
  @moduledoc """
  This module translates a symbol defining a supported event into the actual event and broadcasts it.
  """
  alias EWallet.Web.V1.{
    TransactionRequestConfirmationEvent,
    TransactionRequestConsumptionChangeEvent
  }

  def dispatch(:transaction_request_confirmation, %{consumption: consumption}) do
    TransactionRequestConfirmationEvent.broadcast(consumption)
  end

  def dispatch(:transaction_request_consumption_change, %{consumption: consumption}) do
    TransactionRequestConsumptionChangeEvent.broadcast(consumption)
  end

  def broadcast(
    topic: topic,
    event: event,
    payload: payload
  ) do
    Enum.each(endpoints(), fn endpoint ->
      endpoint.broadcast(
        topic,
        event,
        payload
      )
    end)
  end

  defp endpoints do
    Application.get_env(:ewallet, :websocket_endpoints)
  end
end
