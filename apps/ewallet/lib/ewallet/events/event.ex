defmodule EWallet.Event do
  alias EWallet.{
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
