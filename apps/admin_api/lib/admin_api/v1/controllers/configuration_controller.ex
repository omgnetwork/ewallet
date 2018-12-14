defmodule AdminAPI.V1.ConfigurationController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.Web.{Orchestrator, V1.SettingOverlay}
  alias EWalletConfig.{Config, Repo}
  alias EWallet.ConfigurationPolicy

  def get(conn, attrs) do
    with :ok <- permit(:get, conn.assigns),
         settings =
           Config.query_settings()
           |> Orchestrator.query(SettingOverlay, attrs, Repo) do
      render(conn, :settings, %{settings: settings})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  def update(conn, attrs) do
    with :ok <- permit(:update, conn.assigns),
         {:ok, settings} <- Config.update(attrs) do
      render(conn, :settings_with_errors, %{settings: settings})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  @spec permit(:get | :update, map()) :: any()
  defp permit(action, params) do
    Bodyguard.permit(ConfigurationPolicy, action, params, nil)
  end
end
