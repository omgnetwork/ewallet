defmodule EWalletAPI.V1.Socket do
  use Phoenix.Socket
  alias EWallet.Web.V1.SocketClientAuth

  channel "user:*", EWalletAPI.V1.UserChannel
  channel "transaction_request:*", EWalletAPI.V1.TransactionRequestChannel
  channel "transaction_request_consumption:*", EWalletAPI.V1.TransactionConsumptionChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(params, socket) do
    case SocketClientAuth.authenticate(params) do
      %{authenticated: :client} = auth ->
        {:ok, assign(socket, :auth, auth)}
      auth ->
        {:error, auth.auth_error}
    end
  end

  def id(_socket), do: nil
end
