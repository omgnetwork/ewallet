defmodule KuberaAdmin.V1.SelfController do
  use KuberaAdmin, :controller

  @doc """
  Retrieves the currently authenticated user.
  """
  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end
end
