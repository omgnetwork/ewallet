defmodule EWalletAPI.V1.Socket do
  use Phoenix.Socket

  channel "user:*", EWalletAPI.V1.UserChannel
  channel "transaction_request:*", EWalletAPI.V1.TransactionRequestChannel
  channel "transaction_consumption:*", EWalletAPI.V1.TransactionConsumptionChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(params, socket) do
    # Check Auth
    {:ok, socket}
  end

  def id(_socket), do: nil
end
