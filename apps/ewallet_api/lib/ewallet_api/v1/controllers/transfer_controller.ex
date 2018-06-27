defmodule EWalletAPI.V1.TransferController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.{ErrorHandler}
  alias EWallet.TransactionGate
  alias EWalletAPI.V1.TransactionView

  def transfer_for_user(conn, attrs) do
    attrs
    |> Map.put("from_user_id", conn.assigns.user.id)
    |> TransactionGate.create()
    |> respond(conn)
  end

  defp respond({:ok, transaction}, conn) do
    conn
    |> put_view(TransactionView)
    |> render(:transaction, %{transaction: transaction})
  end

  defp respond({:error, code}, conn), do: handle_error(conn, code)

  defp respond({:error, _transaction, code, description}, conn) do
    handle_error(conn, code, description)
  end
end
