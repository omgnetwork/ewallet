defmodule AdminAPI.StatusController do
  use AdminAPI, :controller

  def status(conn, _attrs) do
    json(conn, %{success: true, api_versions: api_versions(), ewallet_version: "1.1.0"})
  end

  defp api_versions do
    api_versions = Application.get_env(:admin_api, :api_versions)

    Enum.map(api_versions, fn {key, value} ->
      %{name: value[:name], media_type: key}
    end)
  end
end
