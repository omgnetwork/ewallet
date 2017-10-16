defmodule KuberaAPI.V1.StatusController do
  use KuberaAPI, :controller

  def index(conn, _attrs) do
    json conn, %{"success" => :true}
  end
end
