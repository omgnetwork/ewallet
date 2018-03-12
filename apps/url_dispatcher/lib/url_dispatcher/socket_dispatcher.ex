defmodule UrlDispatcher.SocketDispatcher do
  def websockets do
    ewallet_api() ++ admin_api()
  end

  def ewallet_api do
    EWalletAPI.Endpoint.__sockets__
    |> Enum.map(fn {path, socket} ->
      {path, EWalletAPI.Endpoint, socket} |> build_websocket_config("/api")
    end)
  end

  def admin_api do
    []
  end

  defp build_websocket_config({path, endpoint, socket}, prefix) do
    {"#{prefix}#{path}",
       Phoenix.Endpoint.CowboyWebSocket,
       {
         EWalletAPI.WebSocket, {endpoint, socket, :websocket}
      }
     }
  end
end
