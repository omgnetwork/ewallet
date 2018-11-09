defmodule AdminAPI.V1.ConfigurationController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.Web.{Orchestrator, V1.SettingOverlay}
  alias EWalletConfig.{Config, Setting, Repo}

  def get(conn, attrs) do
    settings =
      Config.query_settings()
      |> Orchestrator.query(SettingOverlay, attrs, Repo)

    render(conn, :settings, %{settings: settings})
  end

  def update(conn, attrs) do
    with {:ok, settings} <- Config.update(attrs) do
      render(conn, :settings_with_errors, %{settings: settings})
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end
end
