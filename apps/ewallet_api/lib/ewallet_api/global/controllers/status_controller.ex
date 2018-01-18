defmodule EWalletAPI.StatusController do
  use EWalletAPI, :controller
  alias LocalLedger.Status

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
      :ok ->
        true
      _ ->
        false
    end
  end
end
