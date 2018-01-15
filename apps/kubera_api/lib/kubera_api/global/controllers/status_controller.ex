defmodule KuberaAPI.StatusController do
  use KuberaAPI, :controller
  alias KuberaMQ.Publishers.Status

  def status(conn, _attrs) do
    json conn, %{
      success: true,
      services: %{
        ewallet: true,
        local_ledger: local_ledger()
      }
    }
  end

  defp local_ledger do
    case Status.check() do
      {:ok, _} ->
        true
      _ ->
        false
    end
  end
end
