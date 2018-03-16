defmodule EWalletAPI.V1.Endpoint do
  use Phoenix.Endpoint, otp_app: :ewallet_api

  socket "/socket", EWalletAPI.V1.Socket
end
