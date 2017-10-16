defmodule KuberaAPI.StatusController do
  use KuberaAPI, :controller

  def status(conn, _attrs) do
    json conn, %{status: "ok"}
  end
end
