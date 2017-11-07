defmodule KuberaAPI.V1.SelfController do
  use KuberaAPI, :controller
  alias KuberaDB.MintedToken

  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end

  def get_settings(conn, _attrs) do
    settings = %{minted_tokens: MintedToken.all()}
    render(conn, :settings, settings)
  end
end
