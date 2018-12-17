defmodule AdminAPI.V1.ConfigurationController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.Web.{Orchestrator, Originator, V1.ConfigurationOverlay}
  alias EWalletConfig.{Config, Repo}

  def all(conn, attrs) do
    settings =
      Config.query_settings()
      |> Orchestrator.build_query(ConfigurationOverlay, attrs)
      |> Repo.all()

    render(conn, :settings, %{settings: settings})
  end

  def update(conn, attrs) do
    with attrs <- put_originator(conn, attrs),
         {:ok, settings} <- Config.update(attrs) do
      render(conn, :settings_with_errors, %{settings: settings})
    else
      {:error, code} ->
        handle_error(conn, code)
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
end
