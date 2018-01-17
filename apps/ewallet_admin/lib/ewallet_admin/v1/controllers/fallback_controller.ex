defmodule EWalletAdmin.V1.FallbackController do
  use EWalletAdmin, :controller
  import EWalletAdmin.V1.ErrorHandler

  def not_found(conn, _attrs) do
    handle_error(conn, :endpoint_not_found)
  end
end
