defmodule EWalletAPI.V1.StatusController do
  use EWalletAPI, :controller

  def index(conn, _attrs) do
    json(conn, %{"success" => true})
  end

  @spec server_error(any(), any()) :: no_return()
  def server_error(_conn, _attrs) do
    raise "Mock server error"
  end
end
