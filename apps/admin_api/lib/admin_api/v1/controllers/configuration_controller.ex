defmodule AdminAPI.V1.ConfigurationController do
  use AdminAPI, :controller
  alias EWallet.Web.{Orchestrator, V1.SettingOverlay}
  alias EWalletConfig.{Config, Setting, Repo}

  def get(conn, attrs) do
    settings =
      Config.query_settings()
      |> Orchestrator.query(SettingOverlay, attrs, Repo)

    render(conn, :settings, settings)
  end

  def update(conn, attrs) do
    settings = Config.update_all(attrs)
    render(conn, :settings, settings)
  end
end
