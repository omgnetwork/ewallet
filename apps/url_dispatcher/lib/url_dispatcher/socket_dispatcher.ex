defmodule UrlDispatcher.SocketDispatcher do
  @moduledoc """
  Dispatches websocket connections and payloads to the appropriate sub-application.
  """
  alias EWalletAPI.{WebSocket, V1.Endpoint}
  alias Phoenix.Endpoint.CowboyWebSocket

  def websockets do
    ewallet_api() ++ admin_api()
  end

  def ewallet_api do
    Endpoint.__sockets__
    |> Enum.map(fn {path, socket} ->
      {path, Endpoint, socket} |> build_websocket_config("/api")
    end)
  end

  def admin_api do
    []
  end

  defp build_websocket_config({path, endpoint, socket}, prefix) do
    {"#{prefix}#{path}",
       CowboyWebSocket,
       {
         WebSocket, {endpoint, socket, :websocket}
      }
     }
  end
end
