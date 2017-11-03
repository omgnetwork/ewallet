defmodule KuberaAPI.V1.SelfController do
  use KuberaAPI, :controller

  def get(conn, _attrs) do
    conn |> render(:user, %{user: conn.assigns.user})
  end
end
