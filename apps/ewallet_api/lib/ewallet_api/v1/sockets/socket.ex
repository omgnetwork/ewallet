defmodule EWalletAPI.V1.Socket do
  use Phoenix.Socket
  alias EWallet.Web.V1.{SocketClientAuth, SocketProviderAuth}

  channel "user:*", EWalletAPI.V1.UserChannel
  channel "transaction_request:*", EWalletAPI.V1.TransactionRequestChannel
  channel "transaction_request_consumption:*", EWalletAPI.V1.TransactionConsumptionChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(params, socket) do
    provider_auth = SocketProviderAuth.authenticate(params)
    client_auth   = SocketClientAuth.authenticate(params)

    case {provider_auth, client_auth} do
      {%{authenticated: :provider} = provider_auth, _} ->
        {:ok, assign(socket, :provider_auth, provider_auth)}
      {_, %{authenticated: :client} = client_auth} ->
        {:ok, assign(socket, :client_auth, client_auth)}
      _ ->
        {:error, :auth_error}
    end
  end

  def id(_socket), do: nil
end
