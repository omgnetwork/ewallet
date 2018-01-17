defmodule AdminAPI.StatusController do
  use AdminAPI, :controller

  def status(conn, _attrs) do
    json conn, %{success: true}
  end
end
