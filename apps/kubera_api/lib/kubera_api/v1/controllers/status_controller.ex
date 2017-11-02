defmodule KuberaAPI.V1.StatusController do
  use KuberaAPI, :controller
  alias KuberaMQ.Status

  def index(conn, _attrs) do
    json conn, %{"success" => :true}
  end

  def status_deps(conn, _attrs) do
    Status.check(fn response ->
      json conn, response
    end)

    # This should never be returned.
    json conn, %{success: true, callback: false}
  end

  def server_error(_conn, _attrs) do
    raise "Mock server error"
  end
end
