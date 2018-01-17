defmodule AdminAPI.V1.StatusController do
  use AdminAPI, :controller

  def index(conn, _attrs) do
    json conn, %{success: true}
  end

  def server_error(_conn, _attrs) do
    raise "Mock server error"
  end
end
