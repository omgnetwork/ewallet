defmodule KuberaAPI.StatusController do
  use KuberaAPI, :controller

  def status(conn, _attrs) do
    json conn, %{success: true}
  end
end
