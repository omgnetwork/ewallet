defmodule EWalletAPI.V1.SettingsController do
  use EWalletAPI, :controller
  alias EWalletDB.MintedToken

  def get_settings(conn, _attrs) do
    settings = %{minted_tokens: MintedToken.all()}
    render(conn, :settings, settings)
  end
end
