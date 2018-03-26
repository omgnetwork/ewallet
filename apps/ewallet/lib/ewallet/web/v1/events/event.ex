defmodule EWallet.Web.V1.Event do
  @moduledoc """
  This module translates a symbol defining a supported event into the actual event and broadcasts it.
  """
  alias EWallet.Web.V1.{
    TransactionRequestConfirmationEvent,
    TransactionConsumptionChangeEvent
  }

  @spec dispatch(Atom.t, Map.t) :: :ok
  def dispatch(:transaction_request_confirmation, %{consumption: consumption}) do
    TransactionRequestConfirmationEvent.broadcast(consumption)
  end

  @spec dispatch(Atom.t, Map.t) :: :ok
  def dispatch(:transaction_consumption_change, %{consumption: consumption}) do
    TransactionConsumptionChangeEvent.broadcast(consumption)
  end

  @spec broadcast(Keyword.t) :: :ok
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
