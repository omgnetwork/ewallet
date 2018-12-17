defmodule AdminAPI.V1.ConfigurationController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.Web.{Orchestrator, Originator, V1.SettingOverlay}
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
         attrs <- put_originator(conn, attrs),
         {:ok, settings} <- Config.update(attrs) do
      render(conn, :settings_with_errors, %{settings: settings})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  defp put_originator(conn, attrs) when is_list(attrs) do
    originator = Originator.extract(conn.assigns)

    case Keyword.keyword?(attrs) do
      true ->
        [{:originator, originator} | attrs]

      false ->
        Enum.map(attrs, fn setting_map ->
          Map.put(setting_map, :originator, originator)
        end)
    end
  end

  defp put_originator(conn, attrs) when is_map(attrs) do
    Map.put(attrs, :originator, Originator.extract(conn.assigns))
  end

  @spec permit(:get | :update, map()) :: any()
  defp permit(action, params) do
    Bodyguard.permit(ConfigurationPolicy, action, params, nil)
  end
end
