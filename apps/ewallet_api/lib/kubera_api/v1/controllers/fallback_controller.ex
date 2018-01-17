defmodule EWalletAPI.V1.FallbackController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler

  def not_found(conn, _attrs) do
    handle_error(conn, :endpoint_not_found)
  end
end
