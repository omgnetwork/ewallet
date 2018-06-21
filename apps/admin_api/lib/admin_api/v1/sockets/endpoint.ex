defmodule AdminAPI.V1.Endpoint do
  use Phoenix.Endpoint, otp_app: :admin_api

  socket("/socket/websocket", AdminAPI.V1.Socket)
end
