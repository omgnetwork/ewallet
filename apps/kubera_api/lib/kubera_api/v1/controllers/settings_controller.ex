defmodule KuberaAPI.V1.SettingsController do
  use KuberaAPI, :controller
  alias KuberaDB.MintedToken

  def get_settings(conn, _attrs) do
    settings = %{minted_tokens: MintedToken.all()}
    render(conn, :settings, settings)
  end
end
