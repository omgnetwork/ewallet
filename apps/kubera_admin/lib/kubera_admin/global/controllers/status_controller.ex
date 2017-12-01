defmodule KuberaAdmin.StatusController do
  use KuberaAdmin, :controller

  def status(conn, _attrs) do
    json conn, %{success: true}
  end
end
