defmodule EWalletAPI.StatusController do
  use EWalletAPI, :controller
  alias LocalLedger.Status

  def status(conn, _attrs) do
    json(conn, %{
      success: true,
      nodes: node_count(),
      services: %{
        ewallet: true,
        local_ledger: local_ledger()
      },
      api_versions: api_versions(),
      ewallet_version: Application.get_env(:ewallet, :version)
    })
  end

  defp local_ledger do
    :ok == Status.check()
  end

  defp node_count do
    length(Node.list() ++ [Node.self()])
  end

  defp api_versions do
    api_versions = Application.get_env(:ewallet_api, :api_versions)

    Enum.map(api_versions, fn {key, value} ->
      %{name: value[:name], media_type: key}
    end)
  end
end
