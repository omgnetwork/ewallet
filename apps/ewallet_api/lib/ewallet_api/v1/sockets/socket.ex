defmodule EWalletAPI.V1.Socket do
  @moduledoc """
  This module is the entry points for websocket connections to the eWallet API. It contains the
  channels to which providers/clients can connect to listen and receive events.
  """
  use Phoenix.Socket
  alias EWallet.Web.V1.SocketClientAuth

  channel("account:*", EWalletAPI.V1.AccountChannel)
  channel("user:*", EWalletAPI.V1.UserChannel)
  channel("address:*", EWalletAPI.V1.AddressChannel)
  channel("transaction_request:*", EWalletAPI.V1.TransactionRequestChannel)
  channel("transaction_consumption:*", EWalletAPI.V1.TransactionConsumptionChannel)

  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(params, socket) do
    client_auth = SocketClientAuth.authenticate(params)

    case client_auth do
      %{authenticated: :client} = client_auth ->
        {:ok, assign(socket, :auth, client_auth)}

      _ ->
        :error
    end
  end

  def id(_socket), do: nil
end
