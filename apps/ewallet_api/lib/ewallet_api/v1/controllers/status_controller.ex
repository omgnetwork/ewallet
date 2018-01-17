defmodule EWalletAPI.V1.StatusController do
  use EWalletAPI, :controller
  alias EWalletMQ.Publishers.Status

  def index(conn, _attrs) do
    json conn, %{"success" => :true}
  end

  def status_deps(conn, _attrs) do
    json conn, Status.check()
  end

  def server_error(_conn, _attrs) do
    raise "Mock server error"
  end
end
