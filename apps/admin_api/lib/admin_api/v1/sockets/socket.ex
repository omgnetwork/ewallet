defmodule AdminAPI.V1.Socket do
  @moduledoc """
  This module is the entry points for websocket connections to the admin API. It contains the
  channels to which providers/clients can connect to listen and receive events.
  """
  use Phoenix.Socket
  alias EWallet.Web.V1.SocketProviderAuth

  channel("account:*", AdminAPI.V1.AccountChannel)
  channel("user:*", AdminAPI.V1.UserChannel)
  channel("address:*", AdminAPI.V1.AddressChannel)
  channel("transaction_request:*", AdminAPI.V1.TransactionRequestChannel)
  channel("transaction_consumption:*", AdminAPI.V1.TransactionConsumptionChannel)

  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(params, socket) do
    provider_auth = SocketProviderAuth.authenticate(params)

    case provider_auth do
      %{authenticated: :provider} = provider_auth ->
        {:ok, assign(socket, :auth, provider_auth)}

      _ ->
        :error
    end
  end

  def id(_socket), do: nil
end
