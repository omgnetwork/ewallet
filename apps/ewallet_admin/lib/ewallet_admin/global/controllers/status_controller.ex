defmodule EWalletAdmin.StatusController do
  use EWalletAdmin, :controller

  def status(conn, _attrs) do
    json conn, %{success: true}
  end
end
