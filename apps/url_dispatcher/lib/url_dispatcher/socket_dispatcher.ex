defmodule UrlDispatcher.SocketDispatcher do
  @moduledoc """
  Dispatches websocket connections and payloads to the appropriate sub-application.
  """
  alias Phoenix.Endpoint.CowboyWebSocket

  def websockets do
    ewallet_api() ++ admin_api()
  end

  def ewallet_api do
    EWalletAPI.V1.Endpoint.__sockets__()
    |> Enum.map(fn {path, socket} ->
      {path, EWalletAPI.V1.Endpoint, socket}
      |> build_websocket_config("/api/client", EWalletAPI.WebSocket)
    end)
  end

  def admin_api do
    AdminAPI.V1.Endpoint.__sockets__()
    |> Enum.map(fn {path, socket} ->
      {path, AdminAPI.V1.Endpoint, socket}
      |> build_websocket_config("/api/admin", AdminAPI.WebSocket)
    end)
  end

  defp build_websocket_config({path, endpoint, socket}, prefix, websocket_module) do
    {"#{prefix}#{path}", CowboyWebSocket,
     {
       websocket_module,
       {endpoint, socket, :websocket}
     }}
  end
end
