defmodule AdminAPI.V1.SettingsController do
  use AdminAPI, :controller
  alias EWalletDB.Token

  def get_settings(conn, _attrs) do
    settings = %{tokens: Token.all()}
    render(conn, :settings, settings)
  end
end
